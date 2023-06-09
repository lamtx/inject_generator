import '../models/customer.dart';

abstract interface class Cloud {
  Future<Customer> getCustomer();
}
