import 'package:inject/inject.dart';

import 'models/user.dart';

@module
class AppModule {
  const AppModule();

  @provides
  @singleton
  List<User> provideUserBuilder() {
    throw UnimplementedError();
  }
}
