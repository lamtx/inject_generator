import 'package:get_it/get_it.dart';

import '../app_module.dart';
import '../customer_provide.dart';
import '../models/customer.dart';
import '../models/mask.dart';
import '../models/user.dart';
import '../repository/account_repository.dart';
import '../repository/log_in_repository.dart';
import '../repository/user_repository.dart';
import '../service/cloud.dart';
import '../service/data_source.dart';
import '../testing/cloud_impl.dart';
import '../ui/user_state.dart';

void setupDependencies(GetIt instance) {
  final T = instance.get;
  instance
    ..registerLazySingleton<List<User>>(
        () => const AppModule().provideUserBuilder())
    ..registerFactory<Customer>(provideCustomer)
    ..registerFactory<AccountRepository>(() => AccountRepository(T(), T()))
    ..registerFactory<LoginManager>(LoginManagerImpl.new)
    ..registerFactory<UserRepository>(() => UserRepository(T()))
    ..registerFactory<DataSource>(DataSource.a)
    ..registerFactory<Cloud>(CloudImpl.new)
    ..registerFactoryParam<UserState, int, List<Mask>>(
        (p1, p2) => UserState(p1, p2, T(), T()));
}
