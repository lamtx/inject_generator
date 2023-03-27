import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:inject/inject.dart';
import 'package:source_gen/source_gen.dart';

import '../model/injection_config.dart';

class PackageBuilder implements Builder {
  const PackageBuilder();

  static const _outputFile = "setup_dependencies.dart";
  static final _inputFiles = Glob('lib/**');
  static const _injectTypeChecker = TypeChecker.fromRuntime(Inject);
  static const _moduleTypeChecker = TypeChecker.fromRuntime(Module);
  static const _providesTypeChecker = TypeChecker.fromRuntime(Provides);
  static const _typeChecker = TypeChecker.any([
    _injectTypeChecker,
    _moduleTypeChecker,
    _providesTypeChecker,
  ]);
  static final _formatter =
      DartFormatter(fixes: [StyleFix.singleCascadeStatements]);

  @override
  Map<String, List<String>> get buildExtensions => const {
        r'$lib$': [_outputFile]
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final configs = <InjectionConfig>[];
    final targets = <DartType>[];
    final resolver = buildStep.resolver;
    await for (final input in buildStep.findAssets(_inputFiles)) {
      if (!await resolver.isLibrary(input)) {
        continue;
      }

      final lib = await resolver.libraryFor(
        input,
        allowSyntaxErrors: true,
      );
      for (final generated in _analyzeLibrary(LibraryReader(lib))) {
        if (targets.any((e) => e == generated.target)) {
          throw InvalidGenerationSourceError(
            "Dependency `${generated.target}` is defined multiple times.",
            element: generated.factory,
          );
        }
        final duplicatedName = targets.firstWhereOrNull(
          (e) =>
              e.getDisplayString(withNullability: true) ==
              generated.target.getDisplayString(withNullability: true),
        );
        if (duplicatedName != null) {
          throw InvalidGenerationSourceError(
            "Class with name `$duplicatedName` is defined in both library: `${duplicatedName.element!.librarySource}` and `${generated.target.element!.librarySource}`.\n"
            "Duplicated name in different libraries can cause imports conflict.",
            element: generated.target.element,
          );
        }
        targets.add(generated.target);
        configs.add(generated);
      }
    }
    for (final config in configs) {
      for (final dependency in config.dependencies) {
        if (!targets.contains(dependency)) {
          throw InvalidGenerationSourceError(
            "`${config.target}` depends on `$dependency` but it is unresolvable.",
            element: config.factory,
          );
        }
      }
    }
    final output = _generateOutput(buildStep, configs);

    // Write to the file
    var formattedOutput = output;
    try {
      formattedOutput = _formatter.format(output);
    } catch (e, stack) {
      log.severe(
        '''
An error `${e.runtimeType}` occurred while formatting the generated source for
  `${buildStep.inputId.uri}`
which was output to
  `${_outputFile}`.
This may indicate an issue in the generator, the input source code, or in the
source formatter.''',
        e,
        stack,
      );
    }

    final outputFile = AssetId(buildStep.inputId.package, 'lib/$_outputFile');
    await buildStep.writeAsString(outputFile, formattedOutput);
  }

  Iterable<InjectionConfig> _analyzeLibrary(LibraryReader library) sync* {
    for (final annotatedElement in library.annotatedWith(_typeChecker)) {
      final element = annotatedElement.element;
      final annotation = annotatedElement.annotation;
      if (annotation.instanceOf(_injectTypeChecker)) {
        if (element is ClassElement) {
          yield InjectionConfig.constructor(target: element);
        } else {
          throw InvalidGenerationSourceError(
            "`@${annotation.objectValue.variable!.name}` can only be associated with Class.",
            element: element,
          );
        }
      } else if (annotation.instanceOf(_moduleTypeChecker)) {
        if (element is ClassElement) {
          yield* _analyzeModule(element);
        } else {
          throw InvalidGenerationSourceError(
            "`@${annotation.objectValue.variable!.name}` can only be associated with Class.",
            element: element,
          );
        }
      } else if (annotation.instanceOf(_providesTypeChecker)) {
        if (element is FunctionElement) {
          yield InjectionConfig.method(null, element);
        } else {
          throw InvalidGenerationSourceError(
            "`@${annotation.objectValue.variable!.name}` can only be associated with top-level function or method.",
            element: element,
          );
        }
      } else {
        throw UnsupportedError("Unknown element ${element.declaration}");
      }
    }
  }

  Iterable<InjectionConfig> _analyzeModule(ClassElement classElement) sync* {
    for (final method in classElement.methods) {
      if (_providesTypeChecker.firstAnnotationOf(method) != null) {
        yield InjectionConfig.method(classElement, method);
      }
    }
  }

  String _generateOutput(BuildStep buildStep, List<InjectionConfig> configs) {
    final imports = <String>{};
    for (final config in configs) {
      imports.addAll(config.imports);
    }
    final sb = StringBuffer();
    sb.writeln("import 'package:get_it/get_it.dart';");
    for (final import in imports) {
      sb.writeln("import '$import';");
    }
    sb.writeln("void setupDependencies(GetIt instance) {");
    sb.writeln("final T = instance.get;");
    sb.writeln("instance");
    for (final config in configs) {
      sb.writeln(config.generateCode());
    }
    sb.writeln(";");
    sb.writeln("}");
    return sb.toString();
  }
}

extension on InjectionConfig {
  String generateCode() {
    final registerMethod =
        isSingleton ? "registerLazySingleton" : "registerFactory";
    return "..$registerMethod<${_generateTarget()}>(${_generateFactory()})";
  }

  String _generateTarget() {
    return target.getDisplayString(withNullability: true);
  }

  String _generateFactory() {
    final sb = StringBuffer();
    for (final e in factory.parameters) {
      if (e.isOptional) {
        throw InvalidGenerationSourceError("optional unsupported");
      }
      if (sb.isNotEmpty) {
        sb.write(", ");
      }
      if (e.isPositional) {
        sb.write("T()");
      } else {
        sb
          ..write(e.name)
          ..write(": ")
          ..write("T()");
      }
    }
    if (factory is ConstructorElement) {
      final constructor = factory as ConstructorElement;
      final receiver = constructor.enclosingElement;
      return _combine(
        className: receiver.name,
        methodName: factory.name ?? "",
        params: sb,
        $const: constructor.isConst,
      );
    } else if (factory is MethodElement) {
      final method = factory as MethodElement;
      final receiver = factory.enclosingElement! as ClassElement;
      return _combine(
        className: receiver.name,
        methodName: method.name,
        params: sb,
        static: method.isStatic,
        $const:
            !method.isStatic && (receiver.unnamedConstructor?.isConst ?? false),
      );
    } else if (factory is FunctionElement) {
      return _combine(
        className: null,
        methodName: factory.name!,
        params: sb,
      );
    } else {
      throw UnsupportedError("Unsupported element ${factory.runtimeType}");
    }
  }

  String _combine({
    required String? className,
    required String methodName,
    required StringBuffer params,
    bool $const = false,
    bool static = true,
  }) {
    final tearable = !$const && static && params.isEmpty;
    final modifier = $const ? "const " : "";
    final receiver = className == null
        ? ""
        : static
            ? className
            : "$className()";
    final method = (methodName.isEmpty && tearable) ? "new" : methodName;
    final dot = method.isEmpty || receiver.isEmpty ? "" : ".";
    return tearable
        ? "$receiver$dot$method"
        : "() => $modifier$receiver$dot$method($params)";
  }
}