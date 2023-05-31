import 'package:get_it/get_it.dart';
import 'package:inject_generator_example/main.dart';
import 'package:inject_generator_example/src/models/mask.dart';
import 'package:inject_generator_example/main2.dart';
import 'package:inject_generator_example/src/models/user.dart';
import 'package:inject_generator_example/src/app_module.dart';
import 'package:inject_generator_example/src/models/customer.dart';
import 'package:inject_generator_example/src/customer_provide.dart';

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
