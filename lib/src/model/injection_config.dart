import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:inject/inject.dart';
import 'package:source_gen/source_gen.dart';

import '../misc/misc.dart';

class InjectionConfig {
  InjectionConfig({
    required bool singleton,
    required this.target,
    required this.factory,
  })  : isSingleton = singleton,
        factoryParameters = _collectParameters(factory),
        assert(factory is ConstructorElement ||
            factory is MethodElement ||
            factory is TopLevelFunctionElement) {
    if (!target.element!.isPublic) {
      throw InvalidGenerationSourceError(
        "`${target.element!.name}` has to be public.",
        element: target.element,
      );
    }
    if (singleton && factoryParameters.isNotEmpty) {
      throw InvalidGenerationSourceError(
        "Singleton does not support parameters.",
        element: factory,
      );
    }
  }

  factory InjectionConfig.constructor({
    required ClassElement target,
  }) {
    if (target.typeParameters.isNotEmpty) {
      throw InvalidGenerationSourceError(
        "`${target.name}` is generic class. Generic classes are not constructable without providing their type parameters.",
        element: target,
      );
    }
    if (target.isMixinClass) {
      throw InvalidGenerationSourceError(
        "`${target.name}` is a mixin.",
        element: target,
      );
    }
    if (target.isAbstract) {
      throw InvalidGenerationSourceError(
        "`${target.name}` is abstract class. To provide an instance of abstract class, annotate `@provides` on a static or top level method.",
        element: target,
      );
    }
    if (target.isSealed) {
      throw InvalidGenerationSourceError(
        "`${target.name}` is sealed class. Sealed classes are not constructable.",
        element: target,
      );
    }
    final constructors =
        target.constructors.where((e) => e.isPublic && !e.isFactory).toList();

    if (constructors.isEmpty) {
      throw InvalidGenerationSourceError(
        "`${target.name}` does not have a public constructor.",
        element: target,
      );
    }
    if (constructors.length > 1) {
      throw InvalidGenerationSourceError(
        "`${target.name}` has more than one constructors.",
        element: target,
      );
    }

    return InjectionConfig(
      singleton: target.hasSingleton(),
      target: (target.findBinds() ?? target).thisType,
      factory: constructors.first,
    );
  }

  factory InjectionConfig.method(
    ClassElement? moduleClass,
    ExecutableElement method,
  ) {
    if (!method.isPublic) {
      throw InvalidGenerationSourceError(
        "The provider method has to be public.",
        element: method,
      );
    }
    if (method.isAbstract) {
      throw InvalidGenerationSourceError(
        "The provider method cannot be abstract.",
        element: method,
      );
    }
    if (moduleClass != null && !moduleClass.isPublic) {
      throw InvalidGenerationSourceError(
        "Module has to be public.",
        element: moduleClass,
      );
    }
    if (method.returnType.isDartCoreNull || method.returnType is VoidType) {
      throw InvalidGenerationSourceError(
        "The return type of provider method cannot be void or null.",
        element: method,
      );
    }
    if (moduleClass != null &&
        !moduleClass.hasOnlyDefaultConstructor() &&
        !method.isStatic) {
      throw InvalidGenerationSourceError(
        "The provider method has to be static, top-level function or in a none abstract/sealed class which has only one default constructor.",
        element: method,
      );
    }
    return InjectionConfig(
      target: method.returnType,
      singleton: method.hasSingleton(),
      factory: method,
    );
  }

  final bool isSingleton;

  /// The dependency.
  final DartType target;

  /// The element to create [target], accepts [ConstructorElement],
  /// [MethodElement] or [TopLevelFunctionElement]
  final FunctionTypedElement factory;

  /// The parameters of [factory]
  final List<DartType> factoryParameters;

  List<DartType> get dependencies {
    return factory.formalParameters
        .where((e) => !e.hasParam())
        .map((e) => e.type)
        .toList();
  }

  Set<String> get imports {
    final result = <String>{};
    for (final import in target.collectImports()) {
      result.add(import);
    }
    if (factory is MethodElement) {
      // import the class of this method (static or not)
      result.add(
          (factory.enclosingElement! as ClassElement).library.uri.toString());
    } else if (factory is TopLevelFunctionElement) {
      // import top level function
      result.add(factory.library.uri.toString());
    } else if (factory is ConstructorElement) {
      // import if the class of this constructor is different from the target class
      final clazz = factory.enclosingElement! as ClassElement;
      if (clazz.thisType != target) {
        result.add(clazz.library.uri.toString());
      }
    }
    for (final param in factoryParameters) {
      for (final import in param.collectImports()) {
        result.add(import);
      }
    }
    return result;
  }

  static List<DartType> _collectParameters(FunctionTypedElement factory) {
    final params = <DartType>[];
    for (final param in factory.formalParameters) {
      if (param.hasParam()) {
        params.add(param.type);
      }
    }
    if (params.length > 2) {
      throw InvalidGenerationSourceError(
        "Factory method has more than 2 parameters annotated with `@param`.",
        element: factory,
      );
    }
    return params;
  }
}

const _bindsAnnotationChecker = TypeChecker.typeNamed(Binds);
const _singletonAnnotationChecker = TypeChecker.typeNamed(Singleton);
const _paramAnnotationChecker = TypeChecker.typeNamed(Param);

extension ElementExt on Element {
  bool hasSingleton() => _singletonAnnotationChecker.hasAnnotationOfExact(this);

  bool hasParam() => _paramAnnotationChecker.hasAnnotationOfExact(this);

  ClassElement? findBinds() {
    final annotation = _bindsAnnotationChecker.firstAnnotationOfExact(this);
    if (annotation != null) {
      return annotation.getField("superType")!.toTypeValue()!.element!
          as ClassElement;
    } else {
      return null;
    }
  }
}
