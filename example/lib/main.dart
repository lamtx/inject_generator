import 'package:inject/inject.dart';
import 'package:inject_generator_example/src/models/mask.dart';

import 'src/models/customer.dart';

@inject
class DataSource {
  DataSource.a();

  factory DataSource.b() => DataSource.a();
}

@inject
@singleton
class Cloud {}

@inject
class UserRepository {
  final DataSource datasource;

  UserRepository(this.datasource);
}

@inject
class AccountRepository {
  final DataSource dataSource;
  final Cloud cloud;

  AccountRepository(this.dataSource, this.cloud);
}

abstract class LoginManager {}

@inject
@Binds(LoginManager)
class LoginManagerImpl implements LoginManager {}

@inject
class UserState {
  UserState(
    @param this.id,
    @param this.asyncLoader,
    this.ownerCustomer,
    this._userRepository,
  );

  final int id;
  final List<Mask> asyncLoader;
  final Customer ownerCustomer;
  final UserRepository _userRepository;
}
