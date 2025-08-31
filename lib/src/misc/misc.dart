import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

extension ClassElementExt on ClassElement {
  bool hasOnlyDefaultConstructor() {
    if (!isConstructable) {
      return false;
    }
    final cons = constructors;
    if (cons.length == 1) {
      final constructor = cons.first;
      return constructor.formalParameters.isEmpty && constructor.name == "new";
    } else {
      return false;
    }
  }
}

extension DartTypeExt on DartType {
  bool get isDartCore =>
      isDartCoreNull ||
      isBottom ||
      isDartAsyncFuture ||
      isDartAsyncStream ||
      isDartCoreBool ||
      isDartCoreDouble ||
      isDartCoreEnum ||
      isDartCoreInt ||
      isDartCoreString ||
      isDartCoreList ||
      isDartCoreMap ||
      isDartCoreIterable ||
      isDartCoreRecord ||
      (this is VoidType);

  Iterable<String> collectImports() sync* {
    if (!isDartCore) {
      final source = element?.library?.uri;
      if (source != null) {
        yield source.toString();
      }
    }
    final paramType = this;
    if (paramType is ParameterizedType) {
      for (final param in paramType.typeArguments) {
        if (!param.isDartCore) {
          final source = param.element?.library?.uri;
          if (source != null) {
            yield source.toString();
          }
        }
      }
    }
  }
}
