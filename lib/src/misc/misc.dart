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
      return constructor.parameters.isEmpty && constructor.name.isEmpty;
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
      yield element!.librarySource!.uri.toString();
    }
    final target = this;
    final paramType = target as ParameterizedType;
    for (final param in paramType.typeArguments) {
      if (!param.isDartCore) {
        yield param.element!.librarySource!.uri.toString();
      }
    }
  }
}
