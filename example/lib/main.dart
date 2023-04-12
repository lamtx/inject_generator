import 'package:inject/inject.dart';

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
  UserState(@param this.id, this._userRepository);

  final int id;
  final UserRepository _userRepository;
}
