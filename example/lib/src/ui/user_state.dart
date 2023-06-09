import 'package:inject/inject.dart';

import '../models/customer.dart';
import '../models/mask.dart';
import '../repository/user_repository.dart';

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
