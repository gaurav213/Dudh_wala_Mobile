import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Doodh Wala'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeSystemHint.
  ///
  /// In en, this message translates to:
  /// **'System follows your device setting.'**
  String get themeSystemHint;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langHindi.
  ///
  /// In en, this message translates to:
  /// **'हिंदी'**
  String get langHindi;

  /// No description provided for @langMarathi.
  ///
  /// In en, this message translates to:
  /// **'मराठी'**
  String get langMarathi;

  /// No description provided for @environment.
  ///
  /// In en, this message translates to:
  /// **'Environment'**
  String get environment;

  /// No description provided for @apiBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'API base URL'**
  String get apiBaseUrl;

  /// No description provided for @syncStatus.
  ///
  /// In en, this message translates to:
  /// **'Sync status'**
  String get syncStatus;

  /// No description provided for @conflictResolution.
  ///
  /// In en, this message translates to:
  /// **'Conflict resolution'**
  String get conflictResolution;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @logOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutConfirmTitle;

  /// No description provided for @logOutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logOutConfirmMessage;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @registering.
  ///
  /// In en, this message translates to:
  /// **'Registering…'**
  String get registering;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileNumber;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get emailOptional;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @postalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get postalCode;

  /// No description provided for @defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @outForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for delivery'**
  String get outForDelivery;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @farm.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get farm;

  /// No description provided for @farms.
  ///
  /// In en, this message translates to:
  /// **'Farms'**
  String get farms;

  /// No description provided for @milk.
  ///
  /// In en, this message translates to:
  /// **'Milk'**
  String get milk;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @deliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveries;

  /// No description provided for @quantityL.
  ///
  /// In en, this message translates to:
  /// **'Quantity (L)'**
  String get quantityL;

  /// No description provided for @litres.
  ///
  /// In en, this message translates to:
  /// **'litres'**
  String get litres;

  /// No description provided for @shift.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get shift;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// No description provided for @milkType.
  ///
  /// In en, this message translates to:
  /// **'Milk type'**
  String get milkType;

  /// No description provided for @ratePerLitre.
  ///
  /// In en, this message translates to:
  /// **'Rate / L'**
  String get ratePerLitre;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @amountInr.
  ///
  /// In en, this message translates to:
  /// **'Amount (₹)'**
  String get amountInr;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @bills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get bills;

  /// No description provided for @billing.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get billing;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @generateBill.
  ///
  /// In en, this message translates to:
  /// **'Generate bill'**
  String get generateBill;

  /// No description provided for @generateList.
  ///
  /// In en, this message translates to:
  /// **'Generate list'**
  String get generateList;

  /// No description provided for @cantDeliver.
  ///
  /// In en, this message translates to:
  /// **'Can\'t deliver'**
  String get cantDeliver;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @keepMilk.
  ///
  /// In en, this message translates to:
  /// **'Keep milk'**
  String get keepMilk;

  /// No description provided for @noMilk.
  ///
  /// In en, this message translates to:
  /// **'No milk'**
  String get noMilk;

  /// No description provided for @noMilkThisDay.
  ///
  /// In en, this message translates to:
  /// **'No milk this day'**
  String get noMilkThisDay;

  /// No description provided for @wantMilkAgain.
  ///
  /// In en, this message translates to:
  /// **'I want milk again'**
  String get wantMilkAgain;

  /// No description provided for @farmNotifiedSkipped.
  ///
  /// In en, this message translates to:
  /// **'Farm notified — milk skipped'**
  String get farmNotifiedSkipped;

  /// No description provided for @farmNotifiedRestored.
  ///
  /// In en, this message translates to:
  /// **'Farm notified — milk restored'**
  String get farmNotifiedRestored;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @pickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get pickDate;

  /// No description provided for @customDay.
  ///
  /// In en, this message translates to:
  /// **'Custom day'**
  String get customDay;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @managed.
  ///
  /// In en, this message translates to:
  /// **'Managed'**
  String get managed;

  /// No description provided for @extra.
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get extra;

  /// No description provided for @extraMilk.
  ///
  /// In en, this message translates to:
  /// **'Extra milk'**
  String get extraMilk;

  /// No description provided for @lessMilk.
  ///
  /// In en, this message translates to:
  /// **'Less milk'**
  String get lessMilk;

  /// No description provided for @markDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark delivered'**
  String get markDelivered;

  /// No description provided for @recordCash.
  ///
  /// In en, this message translates to:
  /// **'Record cash'**
  String get recordCash;

  /// No description provided for @out.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get out;

  /// No description provided for @fail.
  ///
  /// In en, this message translates to:
  /// **'Fail'**
  String get fail;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get submitRequest;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get cancelRequest;

  /// No description provided for @cancelRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel request?'**
  String get cancelRequestTitle;

  /// No description provided for @cancelRequestBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this request?'**
  String get cancelRequestBody;

  /// No description provided for @findFarms.
  ///
  /// In en, this message translates to:
  /// **'Find farms'**
  String get findFarms;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptions;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @less.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get less;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @collected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get collected;

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get earned;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @pleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get pleaseTryAgain;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'Internet connection unavailable'**
  String get noInternet;

  /// No description provided for @unableToReachServer.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach server. Check your connection and try again.'**
  String get unableToReachServer;

  /// No description provided for @incorrectCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect mobile number or password.'**
  String get incorrectCredentials;

  /// No description provided for @accountBlocked.
  ///
  /// In en, this message translates to:
  /// **'This account is blocked. Contact support.'**
  String get accountBlocked;

  /// No description provided for @accountNotActive.
  ///
  /// In en, this message translates to:
  /// **'This account is not active yet.'**
  String get accountNotActive;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed. Please try again.'**
  String get signInFailed;

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount.'**
  String get enterValidAmount;

  /// No description provided for @enterValidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid quantity.'**
  String get enterValidQuantity;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter name'**
  String get nameRequired;

  /// No description provided for @mobileRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter mobile number'**
  String get mobileRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get passwordRequired;

  /// No description provided for @invalidMobile.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit mobile number'**
  String get invalidMobile;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @emptyDefault.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyDefault;

  /// No description provided for @couldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load'**
  String get couldNotLoad;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get pullToRefresh;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navFarms.
  ///
  /// In en, this message translates to:
  /// **'Farms'**
  String get navFarms;

  /// No description provided for @navFindFarms.
  ///
  /// In en, this message translates to:
  /// **'Find farms'**
  String get navFindFarms;

  /// No description provided for @navAddresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get navAddresses;

  /// No description provided for @navInbox.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get navInbox;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navTodaysDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Today\'s deliveries'**
  String get navTodaysDeliveries;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navPendingCash.
  ///
  /// In en, this message translates to:
  /// **'Pending cash'**
  String get navPendingCash;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navFarmProfile.
  ///
  /// In en, this message translates to:
  /// **'Farm profile'**
  String get navFarmProfile;

  /// No description provided for @navServiceAreas.
  ///
  /// In en, this message translates to:
  /// **'Service areas'**
  String get navServiceAreas;

  /// No description provided for @navProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get navProducts;

  /// No description provided for @navMilkProducts.
  ///
  /// In en, this message translates to:
  /// **'Milk products'**
  String get navMilkProducts;

  /// No description provided for @navRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get navRequests;

  /// No description provided for @navCustomerRequests.
  ///
  /// In en, this message translates to:
  /// **'Customer requests'**
  String get navCustomerRequests;

  /// No description provided for @navInvitations.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get navInvitations;

  /// No description provided for @navCustomerInvitations.
  ///
  /// In en, this message translates to:
  /// **'Customer invitations'**
  String get navCustomerInvitations;

  /// No description provided for @navFarmInvitations.
  ///
  /// In en, this message translates to:
  /// **'Farm invitations'**
  String get navFarmInvitations;

  /// No description provided for @navStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get navStaff;

  /// No description provided for @navDeliveryStaff.
  ///
  /// In en, this message translates to:
  /// **'Delivery staff'**
  String get navDeliveryStaff;

  /// No description provided for @navExtraRequests.
  ///
  /// In en, this message translates to:
  /// **'Extra requests'**
  String get navExtraRequests;

  /// No description provided for @navCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get navCollections;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navRateCustomers.
  ///
  /// In en, this message translates to:
  /// **'Rate customers'**
  String get navRateCustomers;

  /// No description provided for @navNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// No description provided for @navBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get navBilling;

  /// No description provided for @navBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get navBills;

  /// No description provided for @navPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get navPayments;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @navSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get navSubscriptions;

  /// No description provided for @navDeliveryReport.
  ///
  /// In en, this message translates to:
  /// **'Delivery report'**
  String get navDeliveryReport;

  /// No description provided for @navConnectedCustomers.
  ///
  /// In en, this message translates to:
  /// **'Connected customers'**
  String get navConnectedCustomers;

  /// No description provided for @navServiceRequests.
  ///
  /// In en, this message translates to:
  /// **'Service requests'**
  String get navServiceRequests;

  /// No description provided for @navFarmApprovals.
  ///
  /// In en, this message translates to:
  /// **'Farm approvals'**
  String get navFarmApprovals;

  /// No description provided for @navLegacySuppliers.
  ///
  /// In en, this message translates to:
  /// **'Legacy suppliers'**
  String get navLegacySuppliers;

  /// No description provided for @navAudit.
  ///
  /// In en, this message translates to:
  /// **'Audit'**
  String get navAudit;

  /// No description provided for @navOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get navOutstanding;

  /// No description provided for @farmConsole.
  ///
  /// In en, this message translates to:
  /// **'Farm console'**
  String get farmConsole;

  /// No description provided for @platformConsole.
  ///
  /// In en, this message translates to:
  /// **'Platform console'**
  String get platformConsole;

  /// No description provided for @customerShellTitle.
  ///
  /// In en, this message translates to:
  /// **'My milk account'**
  String get customerShellTitle;

  /// No description provided for @deliveryShellTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery round'**
  String get deliveryShellTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance and language preferences'**
  String get settingsSubtitle;

  /// No description provided for @datesToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get datesToday;

  /// No description provided for @datesYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get datesYesterday;

  /// No description provided for @datesTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get datesTomorrow;

  /// No description provided for @datesThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get datesThisWeek;

  /// No description provided for @datesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get datesThisMonth;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @amounts.
  ///
  /// In en, this message translates to:
  /// **'Amounts'**
  String get amounts;

  /// No description provided for @todaysAmount.
  ///
  /// In en, this message translates to:
  /// **'Today\'s'**
  String get todaysAmount;

  /// No description provided for @givenThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Given this month'**
  String get givenThisMonth;

  /// No description provided for @totalRemaining.
  ///
  /// In en, this message translates to:
  /// **'Total remaining'**
  String get totalRemaining;

  /// No description provided for @reportCashGiven.
  ///
  /// In en, this message translates to:
  /// **'Report cash given'**
  String get reportCashGiven;

  /// No description provided for @reportCashDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Report cash given'**
  String get reportCashDialogTitle;

  /// No description provided for @photoProofRequired.
  ///
  /// In en, this message translates to:
  /// **'Photo proof is required (jpeg / png / webp).'**
  String get photoProofRequired;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @addCashPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo of the cash payment.'**
  String get addCashPhoto;

  /// No description provided for @cashClaimSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Cash claim submitted. Waiting for staff confirmation.'**
  String get cashClaimSubmitted;

  /// No description provided for @desktopCameraHint.
  ///
  /// In en, this message translates to:
  /// **'Camera isn’t available on desktop — use Gallery to pick a photo.'**
  String get desktopCameraHint;

  /// No description provided for @pendingCashTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending cash'**
  String get pendingCashTitle;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @noPendingCash.
  ///
  /// In en, this message translates to:
  /// **'No cash claims waiting for confirmation.'**
  String get noPendingCash;

  /// No description provided for @farmAajKiList.
  ///
  /// In en, this message translates to:
  /// **'Today\'s deliveries'**
  String get farmAajKiList;

  /// No description provided for @farmDiya.
  ///
  /// In en, this message translates to:
  /// **'Mark delivered'**
  String get farmDiya;

  /// No description provided for @farmPaisaLiya.
  ///
  /// In en, this message translates to:
  /// **'Record cash'**
  String get farmPaisaLiya;

  /// No description provided for @farmCustomersTile.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get farmCustomersTile;

  /// No description provided for @farmSetupTile.
  ///
  /// In en, this message translates to:
  /// **'Farm setup'**
  String get farmSetupTile;

  /// No description provided for @farmPaisaTitle.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get farmPaisaTitle;

  /// No description provided for @farmMadeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get farmMadeToday;

  /// No description provided for @farmMadeWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get farmMadeWeek;

  /// No description provided for @farmMadeMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get farmMadeMonth;

  /// No description provided for @farmCollectedToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get farmCollectedToday;

  /// No description provided for @farmCollectedWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get farmCollectedWeek;

  /// No description provided for @farmCollectedMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get farmCollectedMonth;

  /// No description provided for @farmToCollect.
  ///
  /// In en, this message translates to:
  /// **'Outstanding balance'**
  String get farmToCollect;

  /// No description provided for @farmMadeSection.
  ///
  /// In en, this message translates to:
  /// **'Milk earned'**
  String get farmMadeSection;

  /// No description provided for @farmCollectedSection.
  ///
  /// In en, this message translates to:
  /// **'Cash collected'**
  String get farmCollectedSection;

  /// No description provided for @autoGenerateDailyList.
  ///
  /// In en, this message translates to:
  /// **'Auto-generate daily list'**
  String get autoGenerateDailyList;

  /// No description provided for @notGeneratedYet.
  ///
  /// In en, this message translates to:
  /// **'Not generated yet for this date'**
  String get notGeneratedYet;

  /// No description provided for @lastGenerated.
  ///
  /// In en, this message translates to:
  /// **'Last generated {when}'**
  String lastGenerated(String when);

  /// No description provided for @noDeliveryListYet.
  ///
  /// In en, this message translates to:
  /// **'No delivery list for this date yet'**
  String get noDeliveryListYet;

  /// No description provided for @tapGenerateListHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Generate list to create stops from your active customers.'**
  String get tapGenerateListHint;

  /// No description provided for @noCustomersToDeliver.
  ///
  /// In en, this message translates to:
  /// **'No customers to deliver for this date.\nTap Generate list, or check Customers have active milk subscriptions.'**
  String get noCustomersToDeliver;

  /// No description provided for @createdSkippedSummary.
  ///
  /// In en, this message translates to:
  /// **'Created {created}; skipped {skipped}'**
  String createdSkippedSummary(String created, String skipped);

  /// No description provided for @noActiveCustomersDue.
  ///
  /// In en, this message translates to:
  /// **'No active customers due for this date. Check Customers / subscriptions.'**
  String get noActiveCustomersDue;

  /// No description provided for @notifiedCustomersSkipped.
  ///
  /// In en, this message translates to:
  /// **'Notified customers · skipped {n}'**
  String notifiedCustomersSkipped(String n);

  /// No description provided for @customersDontWantMilk.
  ///
  /// In en, this message translates to:
  /// **'{count} customer(s) don’t want milk on {day}'**
  String customersDontWantMilk(String count, String day);

  /// No description provided for @customerDoesNotWantMilk.
  ///
  /// In en, this message translates to:
  /// **'Customer does not want milk this day'**
  String get customerDoesNotWantMilk;

  /// No description provided for @fullDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Full day · {label}'**
  String fullDayLabel(String label);

  /// No description provided for @scheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule · {label}'**
  String scheduleLabel(String label);

  /// No description provided for @deliveryCalendar.
  ///
  /// In en, this message translates to:
  /// **'Delivery calendar'**
  String get deliveryCalendar;

  /// No description provided for @noMilkOnDate.
  ///
  /// In en, this message translates to:
  /// **'No milk on {date}'**
  String noMilkOnDate(String date);

  /// No description provided for @wantMilkOnDate.
  ///
  /// In en, this message translates to:
  /// **'I want milk on {date}'**
  String wantMilkOnDate(String date);

  /// No description provided for @skipMilkConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'No milk this day?'**
  String get skipMilkConfirmTitle;

  /// No description provided for @skipMilkConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'We’ll tell the farm to skip {date}. You won’t be charged for it.'**
  String skipMilkConfirmBody(String date);

  /// No description provided for @wantMilkConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Want milk again?'**
  String get wantMilkConfirmTitle;

  /// No description provided for @wantMilkConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'We’ll tell the farm you want milk on {date} again.'**
  String wantMilkConfirmBody(String date);

  /// No description provided for @skippedNoMilkDay.
  ///
  /// In en, this message translates to:
  /// **'Skipped — no milk this day'**
  String get skippedNoMilkDay;

  /// No description provided for @noDeliveryListedYet.
  ///
  /// In en, this message translates to:
  /// **'No delivery listed yet for this day.\nTap “No milk on …” above to tell the farm, or wait until the farm generates the list.'**
  String get noDeliveryListedYet;

  /// No description provided for @noDeliveriesOnDay.
  ///
  /// In en, this message translates to:
  /// **'No deliveries on this day.'**
  String get noDeliveriesOnDay;

  /// No description provided for @yourDelivery.
  ///
  /// In en, this message translates to:
  /// **'Your delivery'**
  String get yourDelivery;

  /// No description provided for @selectDay.
  ///
  /// In en, this message translates to:
  /// **'Select day'**
  String get selectDay;

  /// No description provided for @lessThanUsualCharged.
  ///
  /// In en, this message translates to:
  /// **'Less than usual · charged for {qty}'**
  String lessThanUsualCharged(String qty);

  /// No description provided for @todaysMilk.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S MILK'**
  String get todaysMilk;

  /// No description provided for @todaysMilkDelivered.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S MILK · Delivered ✓'**
  String get todaysMilkDelivered;

  /// No description provided for @todaysMilkYouSkipped.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S MILK · You skipped'**
  String get todaysMilkYouSkipped;

  /// No description provided for @todayFarmNotDelivering.
  ///
  /// In en, this message translates to:
  /// **'TODAY · Farm not delivering'**
  String get todayFarmNotDelivering;

  /// No description provided for @scheduledMilk.
  ///
  /// In en, this message translates to:
  /// **'Scheduled milk'**
  String get scheduledMilk;

  /// No description provided for @totalDelivered.
  ///
  /// In en, this message translates to:
  /// **'Total delivered'**
  String get totalDelivered;

  /// No description provided for @edited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get edited;

  /// No description provided for @customerStaffBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Customer {customer} · Staff {staff}'**
  String customerStaffBreakdown(String customer, String staff);

  /// No description provided for @inboxSubtitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Invitations and your milk requests'**
  String get inboxSubtitleEmpty;

  /// No description provided for @inboxSubtitleCounts.
  ///
  /// In en, this message translates to:
  /// **'{requests} request(s) · {invitations} invitation(s) pending'**
  String inboxSubtitleCounts(String requests, String invitations);

  /// No description provided for @billsSubtitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Till-date balance & monthly bills'**
  String get billsSubtitleEmpty;

  /// No description provided for @billsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} bill(s)'**
  String billsCount(String count);

  /// No description provided for @farmNotDeliveringBody.
  ///
  /// In en, this message translates to:
  /// **'Your farm is not delivering milk today.'**
  String get farmNotDeliveringBody;

  /// No description provided for @noMilkTodayBtn.
  ///
  /// In en, this message translates to:
  /// **'No milk today'**
  String get noMilkTodayBtn;

  /// No description provided for @skipping.
  ///
  /// In en, this message translates to:
  /// **'Skipping…'**
  String get skipping;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get updating;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating…'**
  String get generating;

  /// No description provided for @customerMilk.
  ///
  /// In en, this message translates to:
  /// **'Customer milk'**
  String get customerMilk;

  /// No description provided for @thisDay.
  ///
  /// In en, this message translates to:
  /// **'This day · {date}'**
  String thisDay(String date);

  /// No description provided for @noMilkStopsCustomer.
  ///
  /// In en, this message translates to:
  /// **'No milk stops for this customer on this day.'**
  String get noMilkStopsCustomer;

  /// No description provided for @tillDateThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Till date (this month)'**
  String get tillDateThisMonth;

  /// No description provided for @deliveredTillDate.
  ///
  /// In en, this message translates to:
  /// **'Delivered till date'**
  String get deliveredTillDate;

  /// No description provided for @extraTillDate.
  ///
  /// In en, this message translates to:
  /// **'Extra till date'**
  String get extraTillDate;

  /// No description provided for @pendingCash.
  ///
  /// In en, this message translates to:
  /// **'Pending cash'**
  String get pendingCash;

  /// No description provided for @advance.
  ///
  /// In en, this message translates to:
  /// **'Advance'**
  String get advance;

  /// No description provided for @milkTillToday.
  ///
  /// In en, this message translates to:
  /// **'Milk till today'**
  String get milkTillToday;

  /// No description provided for @previousDues.
  ///
  /// In en, this message translates to:
  /// **'Previous dues'**
  String get previousDues;

  /// No description provided for @stillDue.
  ///
  /// In en, this message translates to:
  /// **'Still due'**
  String get stillDue;

  /// No description provided for @addAddress.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addAddress;

  /// No description provided for @addAddressFirstForFarms.
  ///
  /// In en, this message translates to:
  /// **'Add a delivery address first so we can find farms that serve you.'**
  String get addAddressFirstForFarms;

  /// No description provided for @searchNow.
  ///
  /// In en, this message translates to:
  /// **'Search now'**
  String get searchNow;

  /// No description provided for @anyFilter.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get anyFilter;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @connectedWithTypes.
  ///
  /// In en, this message translates to:
  /// **'Connected · {types}'**
  String connectedWithTypes(String types);

  /// No description provided for @servesYourPostalCode.
  ///
  /// In en, this message translates to:
  /// **'Serves your postal code'**
  String get servesYourPostalCode;

  /// No description provided for @servesYourArea.
  ///
  /// In en, this message translates to:
  /// **'Serves your area'**
  String get servesYourArea;

  /// No description provided for @servesYourCity.
  ///
  /// In en, this message translates to:
  /// **'Serves your city'**
  String get servesYourCity;

  /// No description provided for @mixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get mixed;

  /// No description provided for @toned.
  ///
  /// In en, this message translates to:
  /// **'Toned'**
  String get toned;

  /// No description provided for @milkTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get milkTypeOther;

  /// No description provided for @requestSentToFarm.
  ///
  /// In en, this message translates to:
  /// **'Request sent to the farm'**
  String get requestSentToFarm;

  /// No description provided for @enterLitres.
  ///
  /// In en, this message translates to:
  /// **'Enter litres'**
  String get enterLitres;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sending;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get sendRequest;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get noReviewsYet;

  /// No description provided for @backToSearch.
  ///
  /// In en, this message translates to:
  /// **'Back to search'**
  String get backToSearch;

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsCount(String count);

  /// No description provided for @maxQtyShort.
  ///
  /// In en, this message translates to:
  /// **'max {qty}'**
  String maxQtyShort(String qty);

  /// No description provided for @tillTodayParen.
  ///
  /// In en, this message translates to:
  /// **'(till today)'**
  String get tillTodayParen;

  /// No description provided for @billTillTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} · till today'**
  String billTillTodayLabel(String label);

  /// No description provided for @noFarmInvitationsYet.
  ///
  /// In en, this message translates to:
  /// **'No invitations from farms yet.\nYou can still find a farm and send a service request.'**
  String get noFarmInvitationsYet;

  /// No description provided for @backToMilkList.
  ///
  /// In en, this message translates to:
  /// **'Back to milk list'**
  String get backToMilkList;

  /// No description provided for @openArrow.
  ///
  /// In en, this message translates to:
  /// **'Open →'**
  String get openArrow;

  /// No description provided for @secretDashboard.
  ///
  /// In en, this message translates to:
  /// **'Secret dashboard'**
  String get secretDashboard;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @deliverTo.
  ///
  /// In en, this message translates to:
  /// **'Deliver to'**
  String get deliverTo;

  /// No description provided for @exactDeliveryPointSaved.
  ///
  /// In en, this message translates to:
  /// **'Exact delivery point saved'**
  String get exactDeliveryPointSaved;

  /// No description provided for @requestMilk.
  ///
  /// In en, this message translates to:
  /// **'Request milk'**
  String get requestMilk;

  /// No description provided for @cancelExtra.
  ///
  /// In en, this message translates to:
  /// **'Cancel extra'**
  String get cancelExtra;

  /// No description provided for @deliver.
  ///
  /// In en, this message translates to:
  /// **'Deliver'**
  String get deliver;

  /// No description provided for @route.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get route;

  /// No description provided for @runMode.
  ///
  /// In en, this message translates to:
  /// **'Run mode'**
  String get runMode;

  /// No description provided for @collections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collections;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @serviceAreas.
  ///
  /// In en, this message translates to:
  /// **'Service areas'**
  String get serviceAreas;

  /// No description provided for @invitations.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get invitations;

  /// No description provided for @staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @connectedCustomers.
  ///
  /// In en, this message translates to:
  /// **'Connected customers'**
  String get connectedCustomers;

  /// No description provided for @farmProfile.
  ///
  /// In en, this message translates to:
  /// **'Farm profile'**
  String get farmProfile;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @notifOutForDeliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Out for delivery'**
  String get notifOutForDeliveryTitle;

  /// No description provided for @notifOutForDeliveryBody.
  ///
  /// In en, this message translates to:
  /// **'Your milk is on the way.'**
  String get notifOutForDeliveryBody;

  /// No description provided for @notifMilkDeliveredTitle.
  ///
  /// In en, this message translates to:
  /// **'Milk delivered'**
  String get notifMilkDeliveredTitle;

  /// No description provided for @notifMilkDeliveredBody.
  ///
  /// In en, this message translates to:
  /// **'Today’s milk has been delivered.'**
  String get notifMilkDeliveredBody;

  /// No description provided for @notifCustomerNoMilkTitle.
  ///
  /// In en, this message translates to:
  /// **'No milk today'**
  String get notifCustomerNoMilkTitle;

  /// No description provided for @notifCustomerNoMilkBody.
  ///
  /// In en, this message translates to:
  /// **'{name} does not want milk on {date}.'**
  String notifCustomerNoMilkBody(String name, String date);

  /// No description provided for @notifCustomerWantsMilkTitle.
  ///
  /// In en, this message translates to:
  /// **'Wants milk again'**
  String get notifCustomerWantsMilkTitle;

  /// No description provided for @notifCustomerWantsMilkBody.
  ///
  /// In en, this message translates to:
  /// **'{name} wants milk on {date} again.'**
  String notifCustomerWantsMilkBody(String name, String date);

  /// No description provided for @notifFarmNoDeliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'No delivery today'**
  String get notifFarmNoDeliveryTitle;

  /// No description provided for @notifFarmNoDeliveryBody.
  ///
  /// In en, this message translates to:
  /// **'Your farm is not delivering milk on {date}.'**
  String notifFarmNoDeliveryBody(String date);

  /// No description provided for @notifCustomerConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery confirmed'**
  String get notifCustomerConfirmedTitle;

  /// No description provided for @notifCustomerConfirmedBody.
  ///
  /// In en, this message translates to:
  /// **'Customer confirmed milk was received.'**
  String get notifCustomerConfirmedBody;

  /// No description provided for @notifExtraRequestedTitle.
  ///
  /// In en, this message translates to:
  /// **'Extra milk requested'**
  String get notifExtraRequestedTitle;

  /// No description provided for @notifExtraAcceptedTitle.
  ///
  /// In en, this message translates to:
  /// **'Extra request accepted'**
  String get notifExtraAcceptedTitle;

  /// No description provided for @notifExtraRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Extra request rejected'**
  String get notifExtraRejectedTitle;

  /// No description provided for @notifCashRecordedTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash payment recorded'**
  String get notifCashRecordedTitle;

  /// No description provided for @notifCashConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash payment confirmed'**
  String get notifCashConfirmedTitle;

  /// No description provided for @notifCashRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash payment rejected'**
  String get notifCashRejectedTitle;

  /// No description provided for @notifRateUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Milk rate updated'**
  String get notifRateUpdatedTitle;

  /// No description provided for @notifServiceRequestCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'New milk request'**
  String get notifServiceRequestCreatedTitle;

  /// No description provided for @notifServiceRequestAcceptedTitle.
  ///
  /// In en, this message translates to:
  /// **'Request accepted'**
  String get notifServiceRequestAcceptedTitle;

  /// No description provided for @notifServiceRequestCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get notifServiceRequestCancelledTitle;

  /// No description provided for @notifGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notifGenericTitle;

  /// No description provided for @extraMilkThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Extra milk this month · {qty}'**
  String extraMilkThisMonth(String qty);

  /// No description provided for @cashAwaitingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cash awaiting staff confirm · {amount}'**
  String cashAwaitingConfirm(String amount);

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @keepRequest.
  ///
  /// In en, this message translates to:
  /// **'Keep request'**
  String get keepRequest;

  /// No description provided for @keepDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Keep deliveries'**
  String get keepDeliveries;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAll;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @purpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get purpose;

  /// No description provided for @billPayment.
  ///
  /// In en, this message translates to:
  /// **'Bill payment'**
  String get billPayment;

  /// No description provided for @pdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get pdf;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get profilePhotoUpdated;

  /// No description provided for @farmName.
  ///
  /// In en, this message translates to:
  /// **'Farm name'**
  String get farmName;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get businessName;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @areaName.
  ///
  /// In en, this message translates to:
  /// **'Area name'**
  String get areaName;

  /// No description provided for @pickCurrentAddress.
  ///
  /// In en, this message translates to:
  /// **'Use my current address'**
  String get pickCurrentAddress;

  /// No description provided for @findingAddress.
  ///
  /// In en, this message translates to:
  /// **'Finding your address…'**
  String get findingAddress;

  /// No description provided for @couldNotReadAddress.
  ///
  /// In en, this message translates to:
  /// **'Could not read your address. You can type it and change any field.'**
  String get couldNotReadAddress;

  /// No description provided for @addressLine1.
  ///
  /// In en, this message translates to:
  /// **'Address line 1'**
  String get addressLine1;

  /// No description provided for @addressLine2.
  ///
  /// In en, this message translates to:
  /// **'Address line 2'**
  String get addressLine2;

  /// No description provided for @nameOptional.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get nameOptional;

  /// No description provided for @customerNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Customer name (optional)'**
  String get customerNameOptional;

  /// No description provided for @commentOptional.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get commentOptional;

  /// No description provided for @chooseAnyDay.
  ///
  /// In en, this message translates to:
  /// **'Choose any day'**
  String get chooseAnyDay;

  /// No description provided for @customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom range'**
  String get customRange;

  /// No description provided for @pickStartAndEndDates.
  ///
  /// In en, this message translates to:
  /// **'Pick start and end dates'**
  String get pickStartAndEndDates;

  /// No description provided for @getSetUp.
  ///
  /// In en, this message translates to:
  /// **'Get set up'**
  String get getSetUp;

  /// No description provided for @farmSetupUntilLive.
  ///
  /// In en, this message translates to:
  /// **'Customers can find your farm and request milk only after these steps. Do them in order.'**
  String get farmSetupUntilLive;

  /// No description provided for @farmSetupAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add farm photos'**
  String get farmSetupAddPhotos;

  /// No description provided for @farmSetupAddPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Optional — helps customers trust your farm'**
  String get farmSetupAddPhotosHint;

  /// No description provided for @farmApproved.
  ///
  /// In en, this message translates to:
  /// **'Farm approved'**
  String get farmApproved;

  /// No description provided for @waitingPlatformApproval.
  ///
  /// In en, this message translates to:
  /// **'Waiting for platform approval'**
  String get waitingPlatformApproval;

  /// No description provided for @completeYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeYourProfile;

  /// No description provided for @profileChecklistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Business name, description & email'**
  String get profileChecklistSubtitle;

  /// No description provided for @addServiceArea.
  ///
  /// In en, this message translates to:
  /// **'Add a service area'**
  String get addServiceArea;

  /// No description provided for @soCustomersCanFindYou.
  ///
  /// In en, this message translates to:
  /// **'So customers can find you'**
  String get soCustomersCanFindYou;

  /// No description provided for @addMilkProduct.
  ///
  /// In en, this message translates to:
  /// **'Add a milk product'**
  String get addMilkProduct;

  /// No description provided for @setRateAndMinQty.
  ///
  /// In en, this message translates to:
  /// **'Set your rate & minimum quantity'**
  String get setRateAndMinQty;

  /// No description provided for @customersToDeliverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customers to deliver — mark as delivered'**
  String get customersToDeliverSubtitle;

  /// No description provided for @productsAreasProfile.
  ///
  /// In en, this message translates to:
  /// **'Products, areas & profile'**
  String get productsAreasProfile;

  /// No description provided for @nConnected.
  ///
  /// In en, this message translates to:
  /// **'{count} connected'**
  String nConnected(String count);

  /// No description provided for @flagForReview.
  ///
  /// In en, this message translates to:
  /// **'Flag for review'**
  String get flagForReview;

  /// No description provided for @billUpdatedTillToday.
  ///
  /// In en, this message translates to:
  /// **'Bill updated for this month (till today)'**
  String get billUpdatedTillToday;

  /// No description provided for @farmProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Farm profile updated'**
  String get farmProfileUpdated;

  /// No description provided for @languagesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Languages updated'**
  String get languagesUpdated;

  /// No description provided for @maxFiveLanguages.
  ///
  /// In en, this message translates to:
  /// **'You can select up to 5 languages.'**
  String get maxFiveLanguages;

  /// No description provided for @spokenLanguages.
  ///
  /// In en, this message translates to:
  /// **'Spoken languages'**
  String get spokenLanguages;

  /// No description provided for @saveLanguages.
  ///
  /// In en, this message translates to:
  /// **'Save languages'**
  String get saveLanguages;

  /// No description provided for @addProductBeforeInvite.
  ///
  /// In en, this message translates to:
  /// **'Add an available product before inviting customers'**
  String get addProductBeforeInvite;

  /// No description provided for @proposedRatePerL.
  ///
  /// In en, this message translates to:
  /// **'Proposed rate (₹/L)'**
  String get proposedRatePerL;

  /// No description provided for @preferredStartDateYmd.
  ///
  /// In en, this message translates to:
  /// **'Preferred start date (YYYY-MM-DD)'**
  String get preferredStartDateYmd;

  /// No description provided for @preferredStartDate.
  ///
  /// In en, this message translates to:
  /// **'Preferred start date'**
  String get preferredStartDate;

  /// No description provided for @deliveryInstructionsOptional.
  ///
  /// In en, this message translates to:
  /// **'Delivery instructions (optional)'**
  String get deliveryInstructionsOptional;

  /// No description provided for @noCustomerInvitationsYet.
  ///
  /// In en, this message translates to:
  /// **'No customer invitations yet.'**
  String get noCustomerInvitationsYet;

  /// No description provided for @startingDate.
  ///
  /// In en, this message translates to:
  /// **'Starting {date}'**
  String startingDate(String date);

  /// No description provided for @noDeliveriesAssignedToday.
  ///
  /// In en, this message translates to:
  /// **'No deliveries assigned today.'**
  String get noDeliveriesAssignedToday;

  /// No description provided for @noDeliveriesInList.
  ///
  /// In en, this message translates to:
  /// **'No deliveries in this list.'**
  String get noDeliveriesInList;

  /// No description provided for @noEditedDeliveriesToday.
  ///
  /// In en, this message translates to:
  /// **'No edited deliveries today.'**
  String get noEditedDeliveriesToday;

  /// No description provided for @noEditedDeliveriesForStaff.
  ///
  /// In en, this message translates to:
  /// **'No edited deliveries for this staff member.'**
  String get noEditedDeliveriesForStaff;

  /// No description provided for @noExtraMilkRecordedToday.
  ///
  /// In en, this message translates to:
  /// **'No extra milk recorded today.'**
  String get noExtraMilkRecordedToday;

  /// No description provided for @deliveryPersonUpdated.
  ///
  /// In en, this message translates to:
  /// **'Delivery person updated'**
  String get deliveryPersonUpdated;

  /// No description provided for @deliveryPerson.
  ///
  /// In en, this message translates to:
  /// **'Delivery person'**
  String get deliveryPerson;

  /// No description provided for @noActiveSubscriptionYet.
  ///
  /// In en, this message translates to:
  /// **'No active subscription yet.'**
  String get noActiveSubscriptionYet;

  /// No description provided for @farmOwnerUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Farm owner (me) / Unassigned'**
  String get farmOwnerUnassigned;

  /// No description provided for @cow.
  ///
  /// In en, this message translates to:
  /// **'Cow'**
  String get cow;

  /// No description provided for @buffalo.
  ///
  /// In en, this message translates to:
  /// **'Buffalo'**
  String get buffalo;

  /// No description provided for @startDateYmd.
  ///
  /// In en, this message translates to:
  /// **'Start date (YYYY-MM-DD)'**
  String get startDateYmd;

  /// No description provided for @mobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile: {number}'**
  String mobileLabel(String number);

  /// No description provided for @pinLabel.
  ///
  /// In en, this message translates to:
  /// **'PIN: {code}'**
  String pinLabel(String code);

  /// No description provided for @radiusKmLabel.
  ///
  /// In en, this message translates to:
  /// **'Radius: {km} km'**
  String radiusKmLabel(String km);

  /// No description provided for @activeYesNo.
  ///
  /// In en, this message translates to:
  /// **'Active: {value}'**
  String activeYesNo(String value);

  /// No description provided for @serviceRadiusKmOptional.
  ///
  /// In en, this message translates to:
  /// **'Service radius (km, optional)'**
  String get serviceRadiusKmOptional;

  /// No description provided for @noServiceAreasYet.
  ///
  /// In en, this message translates to:
  /// **'No service areas yet.'**
  String get noServiceAreasYet;

  /// No description provided for @minimumQuantityL.
  ///
  /// In en, this message translates to:
  /// **'Minimum quantity (L)'**
  String get minimumQuantityL;

  /// No description provided for @maximumQuantityOptional.
  ///
  /// In en, this message translates to:
  /// **'Maximum quantity (optional)'**
  String get maximumQuantityOptional;

  /// No description provided for @availableShifts.
  ///
  /// In en, this message translates to:
  /// **'Available shifts'**
  String get availableShifts;

  /// No description provided for @availableForNewCustomers.
  ///
  /// In en, this message translates to:
  /// **'Available for new customers'**
  String get availableForNewCustomers;

  /// No description provided for @selectAtLeastOneShift.
  ///
  /// In en, this message translates to:
  /// **'Select at least one shift'**
  String get selectAtLeastOneShift;

  /// No description provided for @marketRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Market rate · {name}'**
  String marketRateTitle(String name);

  /// No description provided for @rateUpdatedTo.
  ///
  /// In en, this message translates to:
  /// **'Rate updated to ₹{value}/L'**
  String rateUpdatedTo(String value);

  /// No description provided for @noProductsYet.
  ///
  /// In en, this message translates to:
  /// **'No products yet.'**
  String get noProductsYet;

  /// No description provided for @ratePerLitreValue.
  ///
  /// In en, this message translates to:
  /// **'Rate: ₹{value}/L'**
  String ratePerLitreValue(String value);

  /// No description provided for @changeTodaysRate.
  ///
  /// In en, this message translates to:
  /// **'Change today’s rate'**
  String get changeTodaysRate;

  /// No description provided for @deactivateStaff.
  ///
  /// In en, this message translates to:
  /// **'Deactivate staff'**
  String get deactivateStaff;

  /// No description provided for @reactivateStaff.
  ///
  /// In en, this message translates to:
  /// **'Reactivate staff'**
  String get reactivateStaff;

  /// No description provided for @removeStaff.
  ///
  /// In en, this message translates to:
  /// **'Remove staff'**
  String get removeStaff;

  /// No description provided for @staffDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Staff deactivated'**
  String get staffDeactivated;

  /// No description provided for @staffRemoved.
  ///
  /// In en, this message translates to:
  /// **'Staff removed'**
  String get staffRemoved;

  /// No description provided for @staffStatus.
  ///
  /// In en, this message translates to:
  /// **'Staff status'**
  String get staffStatus;

  /// No description provided for @reassignDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Reassign deliveries'**
  String get reassignDeliveries;

  /// No description provided for @noStaffMembersYet.
  ///
  /// In en, this message translates to:
  /// **'No staff members yet.'**
  String get noStaffMembersYet;

  /// No description provided for @noInvitationsSent.
  ///
  /// In en, this message translates to:
  /// **'No invitations sent.'**
  String get noInvitationsSent;

  /// No description provided for @submitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get submitReview;

  /// No description provided for @thanksForReview.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your review'**
  String get thanksForReview;

  /// No description provided for @requestCancelled.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled'**
  String get requestCancelled;

  /// No description provided for @editRequest.
  ///
  /// In en, this message translates to:
  /// **'Edit request'**
  String get editRequest;

  /// No description provided for @addAddressBeforeRequest.
  ///
  /// In en, this message translates to:
  /// **'Add a delivery address before requesting service'**
  String get addAddressBeforeRequest;

  /// No description provided for @writeAReview.
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get writeAReview;

  /// No description provided for @deliveryNotes.
  ///
  /// In en, this message translates to:
  /// **'Delivery notes'**
  String get deliveryNotes;

  /// No description provided for @deliveryNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Gate code, floor, preferred spot…'**
  String get deliveryNotesHint;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @openMaps.
  ///
  /// In en, this message translates to:
  /// **'Open Maps'**
  String get openMaps;

  /// No description provided for @useCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Use coordinates'**
  String get useCoordinates;

  /// No description provided for @enterValidLatLng.
  ///
  /// In en, this message translates to:
  /// **'Enter valid latitude and longitude.'**
  String get enterValidLatLng;

  /// No description provided for @setAsDefaultAddress.
  ///
  /// In en, this message translates to:
  /// **'Set as default address'**
  String get setAsDefaultAddress;

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get setAsDefault;

  /// No description provided for @pasteFromMaps.
  ///
  /// In en, this message translates to:
  /// **'Paste from Maps'**
  String get pasteFromMaps;

  /// No description provided for @previewInMaps.
  ///
  /// In en, this message translates to:
  /// **'Preview in Maps'**
  String get previewInMaps;

  /// No description provided for @extraMilkRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Extra milk request sent.'**
  String get extraMilkRequestSent;

  /// No description provided for @requestExtraMilk.
  ///
  /// In en, this message translates to:
  /// **'Request extra milk'**
  String get requestExtraMilk;

  /// No description provided for @extraQuantityLitres.
  ///
  /// In en, this message translates to:
  /// **'Extra quantity (litres)'**
  String get extraQuantityLitres;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My requests'**
  String get myRequests;

  /// No description provided for @noExtraMilkRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No extra milk requests yet.'**
  String get noExtraMilkRequestsYet;

  /// No description provided for @updatedThanks.
  ///
  /// In en, this message translates to:
  /// **'Updated. Thanks!'**
  String get updatedThanks;

  /// No description provided for @reportAProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get reportAProblem;

  /// No description provided for @whatWentWrong.
  ///
  /// In en, this message translates to:
  /// **'What went wrong?'**
  String get whatWentWrong;

  /// No description provided for @describeIssueOptional.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue (optional)'**
  String get describeIssueOptional;

  /// No description provided for @deliveryNotFound.
  ///
  /// In en, this message translates to:
  /// **'This delivery could not be found.'**
  String get deliveryNotFound;

  /// No description provided for @noUpdatesYet.
  ///
  /// In en, this message translates to:
  /// **'No updates yet.'**
  String get noUpdatesYet;

  /// No description provided for @thisMonthAndEarlier.
  ///
  /// In en, this message translates to:
  /// **'This month & earlier'**
  String get thisMonthAndEarlier;

  /// No description provided for @couldNotOpenPhotoPicker.
  ///
  /// In en, this message translates to:
  /// **'Could not open photo picker: {error}'**
  String couldNotOpenPhotoPicker(String error);

  /// No description provided for @customerRequired.
  ///
  /// In en, this message translates to:
  /// **'Customer is required'**
  String get customerRequired;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @alternateDays.
  ///
  /// In en, this message translates to:
  /// **'Alternate days'**
  String get alternateDays;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @deliverySlot.
  ///
  /// In en, this message translates to:
  /// **'Delivery slot'**
  String get deliverySlot;

  /// No description provided for @quantityLitres.
  ///
  /// In en, this message translates to:
  /// **'Quantity (litres)'**
  String get quantityLitres;

  /// No description provided for @ratePerLitreInr.
  ///
  /// In en, this message translates to:
  /// **'Rate / litre (₹)'**
  String get ratePerLitreInr;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @defaultRate.
  ///
  /// In en, this message translates to:
  /// **'Default rate'**
  String get defaultRate;

  /// No description provided for @defaultRatePerLitre.
  ///
  /// In en, this message translates to:
  /// **'Default rate / litre (₹)'**
  String get defaultRatePerLitre;

  /// No description provided for @addSubscription.
  ///
  /// In en, this message translates to:
  /// **'Add subscription'**
  String get addSubscription;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get recordPayment;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// No description provided for @noCustomersYet.
  ///
  /// In en, this message translates to:
  /// **'No customers yet. Add your first milk customer.'**
  String get noCustomersYet;

  /// No description provided for @noDeliveriesForTodayYet.
  ///
  /// In en, this message translates to:
  /// **'No deliveries for today yet.'**
  String get noDeliveriesForTodayYet;

  /// No description provided for @deliveryHistory.
  ///
  /// In en, this message translates to:
  /// **'Delivery history'**
  String get deliveryHistory;

  /// No description provided for @quantityColon.
  ///
  /// In en, this message translates to:
  /// **'Quantity: {value}'**
  String quantityColon(String value);

  /// No description provided for @amountColon.
  ///
  /// In en, this message translates to:
  /// **'Amount: {value}'**
  String amountColon(String value);

  /// No description provided for @statusColon.
  ///
  /// In en, this message translates to:
  /// **'Status: {value}'**
  String statusColon(String value);

  /// No description provided for @billCreated.
  ///
  /// In en, this message translates to:
  /// **'Bill {number} created'**
  String billCreated(String number);

  /// No description provided for @periodStart.
  ///
  /// In en, this message translates to:
  /// **'Period start'**
  String get periodStart;

  /// No description provided for @periodEnd.
  ///
  /// In en, this message translates to:
  /// **'Period end'**
  String get periodEnd;

  /// No description provided for @billLines.
  ///
  /// In en, this message translates to:
  /// **'Lines: {count}'**
  String billLines(String count);

  /// No description provided for @subtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal: {amount}'**
  String subtotalLabel(String amount);

  /// No description provided for @noOutstandingDues.
  ///
  /// In en, this message translates to:
  /// **'No outstanding dues. Nice!'**
  String get noOutstandingDues;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @upi.
  ///
  /// In en, this message translates to:
  /// **'UPI'**
  String get upi;

  /// No description provided for @bankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get bankTransfer;

  /// No description provided for @rejectCashClaim.
  ///
  /// In en, this message translates to:
  /// **'Reject cash claim'**
  String get rejectCashClaim;

  /// No description provided for @paymentProof.
  ///
  /// In en, this message translates to:
  /// **'Payment proof'**
  String get paymentProof;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPassword;

  /// No description provided for @futureOtpSms.
  ///
  /// In en, this message translates to:
  /// **'Future: OTP via SMS'**
  String get futureOtpSms;

  /// No description provided for @conflicts.
  ///
  /// In en, this message translates to:
  /// **'Conflicts'**
  String get conflicts;

  /// No description provided for @chooseVersionToKeep.
  ///
  /// In en, this message translates to:
  /// **'Choose which version to keep'**
  String get chooseVersionToKeep;

  /// No description provided for @local.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get local;

  /// No description provided for @remote.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get remote;

  /// No description provided for @noSyncConflicts.
  ///
  /// In en, this message translates to:
  /// **'No sync conflicts.'**
  String get noSyncConflicts;

  /// No description provided for @phase.
  ///
  /// In en, this message translates to:
  /// **'Phase'**
  String get phase;

  /// No description provided for @queue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queue;

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced'**
  String get lastSynced;

  /// No description provided for @lastError.
  ///
  /// In en, this message translates to:
  /// **'Last error'**
  String get lastError;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @searchByDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Search by your delivery address'**
  String get searchByDeliveryAddress;

  /// No description provided for @searchFarmsNearYou.
  ///
  /// In en, this message translates to:
  /// **'Search to see farms delivering near you.'**
  String get searchFarmsNearYou;

  /// No description provided for @noReviewsFromDairyYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews from your dairy yet.'**
  String get noReviewsFromDairyYet;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @methodColon.
  ///
  /// In en, this message translates to:
  /// **'Method: {value}'**
  String methodColon(String value);

  /// No description provided for @couldNotStartApp.
  ///
  /// In en, this message translates to:
  /// **'Could not start the app'**
  String get couldNotStartApp;

  /// No description provided for @addDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Add delivery address'**
  String get addDeliveryAddress;

  /// No description provided for @customersTodayCount.
  ///
  /// In en, this message translates to:
  /// **'{count} customer(s) today'**
  String customersTodayCount(String count);

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @addresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get addresses;

  /// No description provided for @otpPasswordReset.
  ///
  /// In en, this message translates to:
  /// **'OTP password reset'**
  String get otpPasswordReset;

  /// No description provided for @smsOtpLaterRelease.
  ///
  /// In en, this message translates to:
  /// **'SMS OTP verification will land in a later release.'**
  String get smsOtpLaterRelease;

  /// No description provided for @remainingLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String remainingLeft(String count);

  /// No description provided for @hiGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String hiGreeting(String name);

  /// No description provided for @thereFallback.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get thereFallback;

  /// No description provided for @todayDotDate.
  ///
  /// In en, this message translates to:
  /// **'Today · {date}'**
  String todayDotDate(String date);

  /// No description provided for @noDeliveryScheduledOpenCalendar.
  ///
  /// In en, this message translates to:
  /// **'No delivery scheduled today · open calendar'**
  String get noDeliveryScheduledOpenCalendar;

  /// No description provided for @couldNotLoadTodaysMilkRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not load today’s milk. Tap to retry.\n{error}'**
  String couldNotLoadTodaysMilkRetry(String error);

  /// No description provided for @couldNotLoadBillRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not load bill. Tap to retry.\n{error}'**
  String couldNotLoadBillRetry(String error);

  /// No description provided for @amountValue.
  ///
  /// In en, this message translates to:
  /// **'Amount {amount}'**
  String amountValue(String amount);

  /// No description provided for @openDeliveryForExtraHint.
  ///
  /// In en, this message translates to:
  /// **'Open a specific delivery to request extra milk for that day.'**
  String get openDeliveryForExtraHint;

  /// No description provided for @forDate.
  ///
  /// In en, this message translates to:
  /// **'For {date}'**
  String forDate(String date);

  /// No description provided for @openExtraFromDeliveryEnable.
  ///
  /// In en, this message translates to:
  /// **'Open extra milk from a specific delivery to enable requesting.'**
  String get openExtraFromDeliveryEnable;

  /// No description provided for @noDeliveredMilkThisMonthYet.
  ///
  /// In en, this message translates to:
  /// **'No delivered milk this month yet — your bill will show here after the first delivery.'**
  String get noDeliveredMilkThisMonthYet;

  /// No description provided for @dueAmount.
  ///
  /// In en, this message translates to:
  /// **'Due {amount}'**
  String dueAmount(String amount);

  /// No description provided for @billMonthTillToday.
  ///
  /// In en, this message translates to:
  /// **'Bill · {month} (till today)'**
  String billMonthTillToday(String month);

  /// No description provided for @payAnytimeCarryForward.
  ///
  /// In en, this message translates to:
  /// **'Pay anytime this month · unpaid dues carry to next month'**
  String get payAnytimeCarryForward;

  /// No description provided for @inboxPartialMissing.
  ///
  /// In en, this message translates to:
  /// **'Some inbox items may be missing. Pull to refresh.'**
  String get inboxPartialMissing;

  /// No description provided for @inboxEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing in your requests yet.\nFind a farm to request milk, or wait for a farm invitation.'**
  String get inboxEmpty;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @invitationDeclined.
  ///
  /// In en, this message translates to:
  /// **'Invitation declined'**
  String get invitationDeclined;

  /// No description provided for @invitedRelative.
  ///
  /// In en, this message translates to:
  /// **'Invited {when}'**
  String invitedRelative(String when);

  /// No description provided for @requestedRelative.
  ///
  /// In en, this message translates to:
  /// **'Requested {when}'**
  String requestedRelative(String when);

  /// No description provided for @firstDeliveryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'First delivery {date}'**
  String firstDeliveryDateLabel(String date);

  /// No description provided for @nextDeliveryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Next {date}'**
  String nextDeliveryDateLabel(String date);

  /// No description provided for @everyDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get everyDay;

  /// No description provided for @onceAWeek.
  ///
  /// In en, this message translates to:
  /// **'Once a week'**
  String get onceAWeek;

  /// No description provided for @weekdays.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get weekdays;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @invitation.
  ///
  /// In en, this message translates to:
  /// **'Invitation'**
  String get invitation;

  /// No description provided for @startDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start {date}'**
  String startDateLabel(String date);

  /// No description provided for @yourRequest.
  ///
  /// In en, this message translates to:
  /// **'Your request'**
  String get yourRequest;

  /// No description provided for @noFarmsFoundSearch.
  ///
  /// In en, this message translates to:
  /// **'No farms found for this search.'**
  String get noFarmsFoundSearch;

  /// No description provided for @tryDifferentMilkOrShift.
  ///
  /// In en, this message translates to:
  /// **'Try a different milk type or shift, or check back later.'**
  String get tryDifferentMilkOrShift;

  /// No description provided for @productsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} product(s)'**
  String productsCount(String count);

  /// No description provided for @rateThisFarm.
  ///
  /// In en, this message translates to:
  /// **'Rate this farm'**
  String get rateThisFarm;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Status: Pending'**
  String get statusPending;

  /// No description provided for @deliveryDetails.
  ///
  /// In en, this message translates to:
  /// **'Delivery details'**
  String get deliveryDetails;

  /// No description provided for @howOften.
  ///
  /// In en, this message translates to:
  /// **'How often'**
  String get howOften;

  /// No description provided for @weeklyUsesStartWeekday.
  ///
  /// In en, this message translates to:
  /// **'Weekly deliveries use the weekday of your start date.'**
  String get weeklyUsesStartWeekday;

  /// No description provided for @rateMinQty.
  ///
  /// In en, this message translates to:
  /// **'₹{rate}/L · min {qty}'**
  String rateMinQty(String rate, String qty);

  /// No description provided for @noCustomerReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No customer reviews yet.'**
  String get noCustomerReviewsYet;

  /// No description provided for @pasteMapCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Paste map coordinates'**
  String get pasteMapCoordinates;

  /// No description provided for @pasteMapsCoordsHint.
  ///
  /// In en, this message translates to:
  /// **'Open Maps, find your gate, then copy latitude and longitude here. No map API key needed.'**
  String get pasteMapsCoordsHint;

  /// No description provided for @usedWhenPlacingRequests.
  ///
  /// In en, this message translates to:
  /// **'Used when placing new milk requests'**
  String get usedWhenPlacingRequests;

  /// No description provided for @standAtGateMarkDrop.
  ///
  /// In en, this message translates to:
  /// **'Stand at your gate or door and mark the drop point so staff can open Maps there.'**
  String get standAtGateMarkDrop;

  /// No description provided for @noMapPinYet.
  ///
  /// In en, this message translates to:
  /// **'No map pin yet — stand at the drop point and mark it'**
  String get noMapPinYet;

  /// No description provided for @deactivateStaffBody.
  ///
  /// In en, this message translates to:
  /// **'They will not be able to log new deliveries or receive new assignments.'**
  String get deactivateStaffBody;

  /// No description provided for @removeStaffBody.
  ///
  /// In en, this message translates to:
  /// **'Membership will be marked REMOVED. Historical deliveries still show this person.'**
  String get removeStaffBody;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get dangerZone;

  /// No description provided for @totalExtraDelivered.
  ///
  /// In en, this message translates to:
  /// **'Total Extra Delivered: {qty}'**
  String totalExtraDelivered(String qty);

  /// No description provided for @extraMilkColon.
  ///
  /// In en, this message translates to:
  /// **'Extra Milk: {qty}'**
  String extraMilkColon(String qty);

  /// No description provided for @customerRequestedColon.
  ///
  /// In en, this message translates to:
  /// **'Customer requested: {qty}'**
  String customerRequestedColon(String qty);

  /// No description provided for @regularAndExtra.
  ///
  /// In en, this message translates to:
  /// **'Regular {scheduled}\nExtra {extra}'**
  String regularAndExtra(String scheduled, String extra);

  /// No description provided for @todaysRateAppliesHint.
  ///
  /// In en, this message translates to:
  /// **'Today’s rate applies to new milk stops and updates any not-yet-delivered stops for today.'**
  String get todaysRateAppliesHint;

  /// No description provided for @minColon.
  ///
  /// In en, this message translates to:
  /// **'Min: {qty}'**
  String minColon(String qty);

  /// No description provided for @shiftsColon.
  ///
  /// In en, this message translates to:
  /// **'Shifts: {shifts}'**
  String shiftsColon(String shifts);

  /// No description provided for @availableColon.
  ///
  /// In en, this message translates to:
  /// **'Available: {value}'**
  String availableColon(String value);

  /// No description provided for @profilePercentComplete.
  ///
  /// In en, this message translates to:
  /// **'Profile {percent}% complete'**
  String profilePercentComplete(String percent);

  /// No description provided for @milkMetricsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Milk metrics unavailable'**
  String get milkMetricsUnavailable;

  /// No description provided for @stillToCollect.
  ///
  /// In en, this message translates to:
  /// **'Still to collect'**
  String get stillToCollect;

  /// No description provided for @outstandingBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'Outstanding — delivered milk still unpaid, per customer. Another customer’s advance is not subtracted here.'**
  String get outstandingBalanceHint;

  /// No description provided for @advanceHeld.
  ///
  /// In en, this message translates to:
  /// **'Advance held'**
  String get advanceHeld;

  /// No description provided for @advanceHeldHint.
  ///
  /// In en, this message translates to:
  /// **'Extra cash already paid (credit). Shown separately — it does not cancel someone else’s due.'**
  String get advanceHeldHint;

  /// No description provided for @noAppAccountNeeded.
  ///
  /// In en, this message translates to:
  /// **'No app account needed — you manage their milk list.'**
  String get noAppAccountNeeded;

  /// No description provided for @customerAddedGenerateHint.
  ///
  /// In en, this message translates to:
  /// **'Customer added. Open Today’s deliveries and Generate if needed.'**
  String get customerAddedGenerateHint;

  /// No description provided for @statusLifetimeDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Status: {status} · Lifetime deliveries: {count}'**
  String statusLifetimeDeliveries(String status, String count);

  /// No description provided for @editedThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Edited this week: {count}'**
  String editedThisWeek(String count);

  /// No description provided for @noDeliveriesTodayGenerateHint.
  ///
  /// In en, this message translates to:
  /// **'No deliveries for today yet. Tap Generate list, or add customer subscriptions.'**
  String get noDeliveriesTodayGenerateHint;

  /// No description provided for @extraSetTapDiya.
  ///
  /// In en, this message translates to:
  /// **'Extra set to {qty}. Tap Diya to confirm what was delivered.'**
  String extraSetTapDiya(String qty);

  /// No description provided for @pickSingleDayToCancel.
  ///
  /// In en, this message translates to:
  /// **'Pick a single day (Today / Tomorrow / Pick date) to cancel deliveries.'**
  String get pickSingleDayToCancel;

  /// No description provided for @paidColon.
  ///
  /// In en, this message translates to:
  /// **'Paid: {date}'**
  String paidColon(String date);

  /// No description provided for @periodColon.
  ///
  /// In en, this message translates to:
  /// **'Period: {range}'**
  String periodColon(String range);

  /// No description provided for @periodUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Period unavailable'**
  String get periodUnavailable;

  /// No description provided for @todayColonStats.
  ///
  /// In en, this message translates to:
  /// **'Today: {stats}'**
  String todayColonStats(String stats);

  /// No description provided for @replacesStaffExtra.
  ///
  /// In en, this message translates to:
  /// **'Replaces current staff extra'**
  String get replacesStaffExtra;

  /// No description provided for @couldNotLoadAddresses.
  ///
  /// In en, this message translates to:
  /// **'Could not load addresses'**
  String get couldNotLoadAddresses;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @preparingPdf.
  ///
  /// In en, this message translates to:
  /// **'Preparing PDF…'**
  String get preparingPdf;

  /// No description provided for @invitationAccepted.
  ///
  /// In en, this message translates to:
  /// **'Invitation accepted'**
  String get invitationAccepted;

  /// No description provided for @farmInvitation.
  ///
  /// In en, this message translates to:
  /// **'Farm invitation'**
  String get farmInvitation;

  /// No description provided for @requestUpdated.
  ///
  /// In en, this message translates to:
  /// **'Request updated'**
  String get requestUpdated;

  /// No description provided for @noMilkProductsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No milk products are available from this farm right now.'**
  String get noMilkProductsAvailable;

  /// No description provided for @requestPending.
  ///
  /// In en, this message translates to:
  /// **'Request Pending'**
  String get requestPending;

  /// No description provided for @updateExactPoint.
  ///
  /// In en, this message translates to:
  /// **'Update exact point'**
  String get updateExactPoint;

  /// No description provided for @markExactDeliveryPoint.
  ///
  /// In en, this message translates to:
  /// **'Mark exact delivery point'**
  String get markExactDeliveryPoint;

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit customer'**
  String get editCustomer;

  /// No description provided for @addCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add customer'**
  String get addCustomer;

  /// No description provided for @approvedRelative.
  ///
  /// In en, this message translates to:
  /// **'Approved {when}'**
  String approvedRelative(String when);

  /// No description provided for @startShort.
  ///
  /// In en, this message translates to:
  /// **'start {date}'**
  String startShort(String date);

  /// No description provided for @couldNotBuildTodayList.
  ///
  /// In en, this message translates to:
  /// **'Could not build today’s list. Tap Generate list.\n{error}'**
  String couldNotBuildTodayList(String error);

  /// No description provided for @cantDeliverToCustomerTitle.
  ///
  /// In en, this message translates to:
  /// **'Can’t deliver to this customer?'**
  String get cantDeliverToCustomerTitle;

  /// No description provided for @cantDeliverNotifyBody.
  ///
  /// In en, this message translates to:
  /// **'We’ll notify {name} that milk won’t be delivered on {day}.'**
  String cantDeliverNotifyBody(String name, String day);

  /// No description provided for @farmLabel.
  ///
  /// In en, this message translates to:
  /// **'Farm'**
  String get farmLabel;

  /// No description provided for @viewShareBillPdf.
  ///
  /// In en, this message translates to:
  /// **'View / share bill PDF'**
  String get viewShareBillPdf;

  /// No description provided for @contactAdminResetAccess.
  ///
  /// In en, this message translates to:
  /// **'For now, contact your Doodh Wala admin to reset access.'**
  String get contactAdminResetAccess;

  /// No description provided for @synced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get synced;

  /// No description provided for @nPending.
  ///
  /// In en, this message translates to:
  /// **'{n} pending'**
  String nPending(int n);

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This permanently closes your Doodh Wala account and signs you out. Delivery and billing history may remain with farms for their records. This cannot be undone.'**
  String get deleteAccountConfirmMessage;

  /// No description provided for @deleteAccountConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountConfirmAction;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get accountDeleted;

  /// No description provided for @disputed.
  ///
  /// In en, this message translates to:
  /// **'Disputed'**
  String get disputed;

  /// No description provided for @regularExtraLine.
  ///
  /// In en, this message translates to:
  /// **'Regular {regular} · Extra {extra}'**
  String regularExtraLine(String regular, String extra);

  /// No description provided for @extraYouAndStaff.
  ///
  /// In en, this message translates to:
  /// **'(you {you} · staff {staff})'**
  String extraYouAndStaff(String you, String staff);

  /// No description provided for @fromStaffSuffix.
  ///
  /// In en, this message translates to:
  /// **' · from staff'**
  String get fromStaffSuffix;

  /// No description provided for @farmStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get farmStatusActive;

  /// No description provided for @farmStatusPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get farmStatusPendingApproval;

  /// No description provided for @farmStatusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get farmStatusSuspended;

  /// No description provided for @farmStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get farmStatusRejected;

  /// No description provided for @farmStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get farmStatusClosed;

  /// No description provided for @farmStatusBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get farmStatusBlocked;

  /// No description provided for @farmPendingApprovalBanner.
  ///
  /// In en, this message translates to:
  /// **'Your farm is pending approval. You can keep setting up service areas and products — customers will see you once approved.'**
  String get farmPendingApprovalBanner;

  /// No description provided for @farmSuspendedBanner.
  ///
  /// In en, this message translates to:
  /// **'Your farm is currently suspended by the platform.'**
  String get farmSuspendedBanner;

  /// No description provided for @farmRejectedBanner.
  ///
  /// In en, this message translates to:
  /// **'Your farm application was rejected. Contact support for details.'**
  String get farmRejectedBanner;

  /// No description provided for @farmClosedBanner.
  ///
  /// In en, this message translates to:
  /// **'This farm has been closed.'**
  String get farmClosedBanner;

  /// No description provided for @farmNotVisibleBanner.
  ///
  /// In en, this message translates to:
  /// **'This farm is not currently visible to customers.'**
  String get farmNotVisibleBanner;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
