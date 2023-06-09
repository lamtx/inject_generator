import 'package:inject/inject.dart';

@inject
class DataSource {
  DataSource.a();

  factory DataSource.b() => DataSource.a();
}
