class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const registerCustomer = '/register/customer';
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

  // Farm owner marketplace management
  static const farmDashboard = '/farm/dashboard';
  static const farmProfile = '/farm/profile';
  static const farmServiceAreas = '/farm/service-areas';
  static const farmProducts = '/farm/products';
  static const farmStaff = '/farm/staff';
  static const farmRequests = '/farm/requests';
  static String farmRequestDetail(String requestId) =>
      '/farm/requests/$requestId';
  static const farmInvitations = '/farm/invitations';
  static const farmCustomers = '/farm/customers';
  static const farmToday = '/farm/today';
  static const farmNotifications = '/farm/notifications';
  static String farmTodayCustomer(String customerId, {String? date}) {
    final base = '/farm/today/$customerId';
    if (date == null || date.isEmpty) return base;
    return '$base?date=$date';
  }
  static const farmDeliveriesEdited = '/farm/deliveries/edited';
  static const farmExtraToday = '/farm/deliveries/extra';
  static const farmCollections = '/farm/collections';
  static String farmStaffDetail(String staffUserId) =>
      '/farm/staff/$staffUserId';
  static String farmStaffToday(String staffUserId) =>
      '/farm/staff/$staffUserId/today';
  static String farmStaffEdited(String staffUserId) =>
      '/farm/staff/$staffUserId/edited';
  static String farmStaffSettings(String staffUserId) =>
      '/farm/staff/$staffUserId/settings';
  static String farmDeliveryEditReview(String deliveryId) =>
      '/farm/deliveries/$deliveryId/edit-review';
  static String farmCustomerDelivery(String customerId, String deliveryId) =>
      '/farm/customers/$customerId/deliveries/$deliveryId';

  // Customer marketplace
  static const customerDashboard = '/customer/dashboard';
  static const customerAddresses = '/customer/addresses';
  static const customerFindFarms = '/customer/farms';
  static String customerFarmDetail(String farmId) => '/customer/farms/$farmId';
  static const customerRequests = '/customer/requests';
  static const customerInvitations = '/customer/invitations';

  // Delivery-staff shell
  static const deliveryDashboard = '/delivery/dashboard';
  static const deliveryCustomers = '/delivery/customers';
  static String deliveryCustomerDetail(String customerId) =>
      '/delivery/customers/$customerId';
  static const deliveryToday = '/delivery/today';
  static String deliveryTodayFiltered(String filter) =>
      '/delivery/today?filter=$filter';
  static String deliveryDeliveryDetail(String deliveryId) =>
      '/delivery/deliveries/$deliveryId';
  static String deliveryDeliveryEdit(String deliveryId) =>
      '/delivery/deliveries/$deliveryId/edit';
  static const deliveryRunMode = '/delivery/today/run';
  static const deliveryRoute = '/delivery/route';
  static const deliveryExtraRequests = '/delivery/extra-requests';
  static const deliveryCollections = '/delivery/collections';
  static const deliveryPendingCash = '/delivery/pending-cash';
  static const deliveryStaffHistory = '/delivery/history';
  static const deliveryReviews = '/delivery/reviews';
  static const deliveryNotifications = '/delivery/notifications';
  static const deliveryProfile = '/delivery/profile';

  // Customer delivery experience
  static String customerDeliveryDetail(String deliveryId) =>
      '/customer/deliveries/$deliveryId';
  static const customerExtraRequest = '/customer/extra-request';
  static const customerBilling = '/customer/billing';
  static const customerReviewsReceived = '/customer/reviews/received';
  static const customerNotifications = '/customer/notifications';
  static String notificationDetail(String recipientId) =>
      '/notification-detail/$recipientId';
}
