import 'package:inject/inject.dart';

abstract class LoginManager {}

@inject
@Binds(LoginManager)
class LoginManagerImpl implements LoginManager {}
