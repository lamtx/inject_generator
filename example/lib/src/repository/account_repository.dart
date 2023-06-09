import 'package:inject/inject.dart';

import '../service/cloud.dart';
import '../service/data_source.dart';

@inject
class AccountRepository {
  AccountRepository(this.dataSource, this.cloud);

  final DataSource dataSource;
  final Cloud cloud;
}
