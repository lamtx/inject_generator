import 'package:get_it/get_it.dart';

import 'main.dart';
import 'main2.dart';
import 'src/app_module.dart';
import 'src/customer_provide.dart';
import 'src/models/customer.dart';
import 'src/models/mask.dart';
import 'src/models/user.dart';

void setupDependencies(GetIt instance) {
  final T = instance.get;
  instance
    ..registerFactory<DataSource>(DataSource.a)
    ..registerLazySingleton<Cloud>(Cloud.new)
    ..registerFactory<UserRepository>(() => UserRepository(T()))
    ..registerFactory<AccountRepository>(() => AccountRepository(T(), T()))
    ..registerFactory<LoginManager>(LoginManagerImpl.new)
    ..registerFactoryParam<UserState, int, List<Mask>>(
        (p1, p2) => UserState(p1, p2, T(), T()))
    ..registerFactory<DataSource2>(() => DataSource2(T()))
    ..registerLazySingleton<List<User>>(
        () => const AppModule().provideUserBuilder())
    ..registerFactory<Customer>(provideCustomer);
}
