import 'package:inject/inject.dart';

import '../service/data_source.dart';

@inject
class UserRepository {
  UserRepository(this.datasource);

  final DataSource datasource;
}
