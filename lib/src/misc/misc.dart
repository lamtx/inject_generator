import 'package:analyzer/dart/element/element.dart';

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
