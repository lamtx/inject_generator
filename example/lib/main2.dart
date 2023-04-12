import 'package:inject/inject.dart';

import 'src/models/user.dart';

@inject
class DataSource2 {
  DataSource2(this.user);

  final List<User> user;
}
