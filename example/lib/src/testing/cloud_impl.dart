import 'package:inject/inject.dart';

import '../models/customer.dart';
import '../service/cloud.dart';

@inject
@Binds(Cloud)
class CloudImpl implements Cloud {
  @override
  Future<Customer> getCustomer() {
    throw UnimplementedError();
  }
}
