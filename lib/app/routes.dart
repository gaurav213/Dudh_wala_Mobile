class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  static const supplierHome = '/supplier';
  static const customerHome = '/customer';

  static const todaysDeliveries = '/deliveries/today';
  static const deliveryHistory = '/deliveries/history';
  static const calendar = '/calendar';

  static const customers = '/customers';
  static String customerDetails(String id) => '/customers/$id';
  static const customerForm = '/customers/form';
  static String customerFormWithId(String id) => '/customers/form/$id';

  static const subscriptionForm = '/subscriptions/form';

  static const bills = '/bills';
  static String billDetails(String id) => '/bills/$id';
  static const generateBill = '/bills/generate';
  static const outstanding = '/bills/outstanding';

  static const recordPayment = '/payments/record';
  static const paymentHistory = '/payments/history';

  static const profile = '/profile';
  static const settings = '/settings';
  static const syncStatus = '/settings/sync';
  static const conflicts = '/settings/conflicts';
  static const notifications = '/notifications';

  // Customer-scoped paths (avoid clashing with supplier shell routes)
  static const customerCalendar = '/customer/calendar';
  static const customerHistory = '/customer/history';
  static const customerBills = '/customer/bills';
  static const customerPayments = '/customer/payments';
  static const customerProfile = '/customer/profile';
}
