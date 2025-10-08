// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Genie On Call';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get settings => 'Settings';

  @override
  String get home => 'Home';

  @override
  String get myBookings => 'My Bookings';

  @override
  String get myEarnings => 'My Earnings';

  @override
  String get chat => 'Chat';

  @override
  String get accept => 'Accept';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get remove => 'Remove';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get sort => 'Sort';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Information';

  @override
  String get retry => 'Retry';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get continueButton => 'Continue';

  @override
  String get skip => 'Skip';

  @override
  String get done => 'Done';

  @override
  String get close => 'Close';

  @override
  String get open => 'Open';

  @override
  String get select => 'Select';

  @override
  String get choose => 'Choose';

  @override
  String get pick => 'Pick';

  @override
  String get submit => 'Submit';

  @override
  String get send => 'Send';

  @override
  String get receive => 'Receive';

  @override
  String get welcome => 'Welcome';

  @override
  String get hello => 'Hello';

  @override
  String get goodbye => 'Goodbye';

  @override
  String get thankYou => 'Thank you';

  @override
  String get please => 'Please';

  @override
  String get sorry => 'Sorry';

  @override
  String get help => 'Help';

  @override
  String get support => 'Support';

  @override
  String get contact => 'Contact';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get theme => 'Theme';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get notifications => 'Notifications';

  @override
  String get location => 'Location';

  @override
  String get permissions => 'Permissions';

  @override
  String get services => 'Services';

  @override
  String get bookings => 'Bookings';

  @override
  String get earnings => 'Earnings';

  @override
  String get profile => 'Profile';

  @override
  String get account => 'Account';

  @override
  String get password => 'Password';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get name => 'Name';

  @override
  String get address => 'Address';

  @override
  String get city => 'City';

  @override
  String get state => 'State';

  @override
  String get country => 'Country';

  @override
  String get zipCode => 'Zip Code';

  @override
  String get description => 'Description';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get duration => 'Duration';

  @override
  String get price => 'Price';

  @override
  String get cost => 'Cost';

  @override
  String get total => 'Total';

  @override
  String get amount => 'Amount';

  @override
  String get payment => 'Payment';

  @override
  String get paid => 'Paid';

  @override
  String get pending => 'Pending';

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get accepted => 'Accepted';

  @override
  String get rejected => 'Rejected';

  @override
  String get inProgress => 'In Progress';

  @override
  String get finished => 'Finished';

  @override
  String get available => 'Available';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get required => 'Required';

  @override
  String get optional => 'Optional';

  @override
  String get yesNoDialogTitle => 'Confirmation';

  @override
  String get yesNoDialogContent => 'Are you sure you want to proceed?';

  @override
  String get languageChangeDialogTitle => 'Change Language';

  @override
  String languageChangeDialogContent(Object language) {
    return 'Are you sure you want to change the language to $language? The app will restart to apply the changes.';
  }

  @override
  String get logoutConfirmationTitle => 'Logout';

  @override
  String get logoutConfirmationContent => 'Are you sure you want to log out?';

  @override
  String get locationPermissionTitle => 'Location Permission';

  @override
  String get locationPermissionContent =>
      'Location permissions are required to filter jobs by distance.';

  @override
  String get notificationPermissionTitle => 'Notification Permission';

  @override
  String get notificationPermissionContent =>
      'Push notifications are required to receive job alerts.';

  @override
  String get appPreferences => 'App Preferences';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get notificationsEnabled => 'Notifications are enabled';

  @override
  String get notificationsDisabled =>
      'Notifications are disabled. Tap to open settings.';

  @override
  String get locationServices => 'Location Services';

  @override
  String get locationServicesInfo =>
      'Location permission is managed automatically. If denied, we use previously stored location details for better service matching.';

  @override
  String get myServices => 'My Services';

  @override
  String get addService => 'Add Service';

  @override
  String distanceRange(Object range) {
    return 'Distance Range: $range km';
  }

  @override
  String get nearbyJobs => 'Nearby Jobs';

  @override
  String get noNearbyJobs => 'No nearby jobs available.';

  @override
  String get noMatchingJobs => 'No matching jobs.';

  @override
  String get acceptedJobs => 'Accepted Jobs';

  @override
  String earningsAmount(Object amount) {
    return '₹$amount';
  }

  @override
  String bookingDateTime(Object date, Object time) {
    return 'Date: $date\nTime: $time';
  }

  @override
  String bookingDetails(Object name, Object phone) {
    return 'Name: $name, Mobile: $phone';
  }

  @override
  String get bookingAccepted => 'Booking accepted!';

  @override
  String errorAcceptingBooking(Object error) {
    return 'Error accepting booking: $error';
  }

  @override
  String get checkingStatus => 'Checking status...';

  @override
  String get tapToOpenSettings => 'Tap to open settings.';

  @override
  String get genieOnCallAgent => 'Genie On Call - Agent';

  @override
  String get agentUser => 'Agent User';

  @override
  String get customer => 'Customer';

  @override
  String get notProvided => 'Not provided';

  @override
  String get locationNotAvailable => 'Location not available';

  @override
  String get timeNotSpecified => 'Time not specified';

  @override
  String get unknownService => 'Unknown Service';

  @override
  String get running => 'running';

  @override
  String get noServicesAvailable => 'No services available.';

  @override
  String get noBookingsAvailable => 'No bookings available.';

  @override
  String errorGettingLocation(Object error) {
    return 'Error getting location: $error';
  }

  @override
  String genericError(Object error) {
    return 'Error: $error';
  }

  @override
  String get noSubServicesFound => 'No sub-services found for this service.';

  @override
  String get noSubServicesDefined =>
      'No sub-services defined for this service.';

  @override
  String get mustBeLoggedIn => 'You must be logged in to book a service.';

  @override
  String failedToBookService(Object error) {
    return 'Failed to book service: $error';
  }

  @override
  String get locationPermissionDenied => 'Location permission denied';

  @override
  String get failedToGetCurrentLocation => 'Failed to get current location';

  @override
  String get addImages => 'Add Images';

  @override
  String get errorLoadingChats => 'Error loading chats';

  @override
  String get errorLoadingMessages => 'Error loading messages';

  @override
  String get errorGettingLocationShort => 'Location not available';

  @override
  String get bookingAcceptedSnackbar => 'Booking accepted!';

  @override
  String errorAcceptingBookingSnackbar(Object error) {
    return 'Error accepting booking: $error';
  }

  @override
  String get noServicesAvailableText => 'No services available.';

  @override
  String errorFetchingEarnings(Object error) {
    return 'Error fetching earnings: $error';
  }

  @override
  String get noEarningsYet => 'No earnings yet.';

  @override
  String get bookingFinishedAndEarningsUpdated =>
      'Booking marked as finished and earnings updated!';

  @override
  String errorFinishingBooking(Object error) {
    return 'Error finishing booking: $error';
  }

  @override
  String get locationNotAvailableShort => 'Location not available';

  @override
  String get couldNotLaunchMaps => 'Could not launch maps app';

  @override
  String get newNotification => 'New Notification';

  @override
  String get view => 'VIEW';

  @override
  String get selectRole => 'Select Your Role';

  @override
  String get user => 'User';

  @override
  String get agent => 'Agent';

  @override
  String continueAs(Object role) {
    return 'Continue as $role';
  }

  @override
  String get enterPhoneNumber => 'Enter Phone Number';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get sendOTP => 'Send OTP';

  @override
  String get enterOTP => 'Enter OTP';

  @override
  String get verifyOTP => 'Verify OTP';

  @override
  String get invalidOTP => 'Invalid OTP';

  @override
  String otpSent(Object phone) {
    return 'OTP sent to $phone';
  }

  @override
  String get resendOTP => 'Resend OTP';

  @override
  String get otpResent => 'OTP resent';

  @override
  String get loginSuccessful => 'Login successful';

  @override
  String loginFailed(Object error) {
    return 'Login failed: $error';
  }

  @override
  String get registrationSuccessful => 'Registration successful';

  @override
  String registrationFailed(Object error) {
    return 'Registration failed: $error';
  }

  @override
  String get selectServices => 'Select Services';

  @override
  String get selectAtLeastOneService => 'Please select at least one service';

  @override
  String get serviceSelectionComplete => 'Service selection complete';

  @override
  String get enterDetails => 'Enter Details';

  @override
  String get fullName => 'Full Name';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get profileSaved => 'Profile saved successfully';

  @override
  String profileSaveFailed(Object error) {
    return 'Failed to save profile: $error';
  }

  @override
  String get bookingSuccessful => 'Booking Successful';

  @override
  String get bookingFailed => 'Booking Failed';

  @override
  String get paymentSuccessful => 'Payment Successful';

  @override
  String get paymentFailed => 'Payment Failed';

  @override
  String get bookingConfirmed => 'Your booking has been confirmed';

  @override
  String get bookingConfirmedTitle => 'Booking Confirmed!';

  @override
  String get bookingConfirmedMessage =>
      'Service is booked, an executive will be assigned as soon as possible.';

  @override
  String get okButtonLabel => 'OK';

  @override
  String get selectPaymentMethod => 'Select Payment Method';

  @override
  String get chatsWithExecutive => 'Chats with Executive';

  @override
  String get noChatsYet => 'No chats yet. Start a new conversation.';

  @override
  String get loginRequiredTitle => 'Login Required';

  @override
  String get startNewChatTitle => 'Start New Chat';

  @override
  String get subjectLabel => 'Subject';

  @override
  String get enterChatSubjectHint => 'Enter chat subject';

  @override
  String get startButtonLabel => 'Start';

  @override
  String get missingDetailsTitle => 'Missing Details';

  @override
  String get missingDetailsContent => 'Please enter your name and address.';

  @override
  String get selectionRequiredTitle => 'Selection Required';

  @override
  String get selectionRequiredContent => 'Please select a date and time slot.';

  @override
  String get newChat => 'New Chat';

  @override
  String get agentProfile => 'Agent Profile';

  @override
  String get manageProfileAndServices => 'Manage your profile and services';

  @override
  String get incompleteProfileTitle => 'Incomplete Profile';

  @override
  String get pleaseFillAllFields => 'Please fill all fields.';

  @override
  String get servicesOffered => 'Services Offered';

  @override
  String get selectServicesPlaceholder => 'Select services';

  @override
  String get yearsOfExperience => 'Years of Experience';

  @override
  String get detectingLocation => 'Detecting location...';

  @override
  String locationDisplay(Object lat, Object lng) {
    return 'Location: $lat, $lng';
  }

  @override
  String get locationNotDetected => 'Location not detected';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String get telugu => 'Telugu';

  @override
  String get tenglish => 'Tenglish';

  @override
  String get hinglish => 'Hinglish';

  @override
  String bookingId(Object id) {
    return 'Booking ID: $id';
  }

  @override
  String get serviceProvider => 'Service Provider';

  @override
  String get bookingDate => 'Booking Date';

  @override
  String get bookingTime => 'Booking Time';

  @override
  String get serviceLocation => 'Service Location';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get cashOnDelivery => 'Cash on Delivery';

  @override
  String get onlinePayment => 'Online Payment';

  @override
  String get proceedToPayment => 'Proceed to Payment';

  @override
  String get confirmBooking => 'Confirm Booking';

  @override
  String get bookingSummary => 'Booking Summary';

  @override
  String get change => 'Change';

  @override
  String get apply => 'Apply';

  @override
  String get discount => 'Discount';

  @override
  String get tax => 'Tax';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get grandTotal => 'Grand Total';

  @override
  String get termsAndConditions => 'Terms and Conditions';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get aboutUs => 'About Us';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get faq => 'FAQ';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get rateUs => 'Rate Us';

  @override
  String get shareApp => 'Share App';

  @override
  String get feedback => 'Feedback';

  @override
  String get reportIssue => 'Report Issue';

  @override
  String appVersion(Object version) {
    return 'App Version $version';
  }

  @override
  String get developedBy => 'Developed by';

  @override
  String get copyright => '© 2024 All rights reserved';

  @override
  String get addressLabel => 'Address : ';

  @override
  String get dateLabel => 'Date: ';

  @override
  String get timeLabel => 'Time: ';

  @override
  String get nameLabel => 'Name: ';

  @override
  String get mobileLabel => 'Mobile: ';

  @override
  String get distanceRangeLabel => 'Distance Range: ';

  @override
  String get km => 'km';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get optionalLabel => 'Optional';

  @override
  String get describeService => 'Describe your service needs';

  @override
  String get describeServiceHint => 'e.g., I need plumbing for kitchen sink';

  @override
  String get recordVoice => 'Record Voice';

  @override
  String get stopRecording => 'Stop Recording';

  @override
  String get playRecording => 'Play Recording';

  @override
  String get stopPlayback => 'Stop Playback';
}

/// The translations for English (`en_HI`).
class AppLocalizationsEnHi extends AppLocalizationsEn {
  AppLocalizationsEnHi() : super('en_HI');

  @override
  String get appTitle => 'जीन ऑन कॉल';

  @override
  String get login => 'Login karo';

  @override
  String get logout => 'Logout karo';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get home => 'होम';

  @override
  String get myBookings => 'Meri Bookings';

  @override
  String get myEarnings => 'Meri Kamai';

  @override
  String get chat => 'चैट';

  @override
  String get accept => 'Accept karo';

  @override
  String get cancel => 'Cancel karo';

  @override
  String get confirm => 'Confirm karo';

  @override
  String get yes => 'Haan';

  @override
  String get no => 'Nahi';

  @override
  String get ok => 'Theek hai';

  @override
  String get save => 'Save karo';

  @override
  String get delete => 'Delete karo';

  @override
  String get edit => 'Edit karo';

  @override
  String get add => 'Add karo';

  @override
  String get remove => 'Remove karo';

  @override
  String get search => 'Search karo';

  @override
  String get filter => 'फिल्टर';

  @override
  String get sort => 'सॉर्ट';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get error => 'त्रुटि';

  @override
  String get success => 'सफलता';

  @override
  String get warning => 'चेतावनी';

  @override
  String get info => 'Info';

  @override
  String get retry => 'Retry karo';

  @override
  String get back => 'वापस';

  @override
  String get next => 'अगला';

  @override
  String get previous => 'पिछला';

  @override
  String get continueButton => 'Aage';

  @override
  String get skip => 'छोड़ें';

  @override
  String get done => 'हो गया';

  @override
  String get close => 'बंद करें';

  @override
  String get open => 'खोलें';

  @override
  String get select => 'Select karo';

  @override
  String get choose => 'Choose karo';

  @override
  String get pick => 'Pick karo';

  @override
  String get submit => 'Submit karo';

  @override
  String get send => 'Send karo';

  @override
  String get receive => 'Receive karo';

  @override
  String get welcome => 'स्वागत';

  @override
  String get hello => 'नमस्ते';

  @override
  String get goodbye => 'अलविदा';

  @override
  String get thankYou => 'धन्यवाद';

  @override
  String get please => 'कृपया';

  @override
  String get sorry => 'माफ़ कीजिए';

  @override
  String get help => 'मदद';

  @override
  String get support => 'सपोर्ट';

  @override
  String get contact => 'संपर्क';

  @override
  String get about => 'के बारे में';

  @override
  String get version => 'संस्करण';

  @override
  String get language => 'भाषा';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get theme => 'थीम';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get lightMode => 'लाइट मोड';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get location => 'स्थान';

  @override
  String get permissions => 'अनुमतियां';

  @override
  String get services => 'सेवाएं';

  @override
  String get bookings => 'बुकिंग';

  @override
  String get earnings => 'कमाई';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get account => 'खाता';

  @override
  String get password => 'पासवर्ड';

  @override
  String get email => 'ईमेल';

  @override
  String get phone => 'फोन';

  @override
  String get name => 'नाम';

  @override
  String get address => 'पता';

  @override
  String get city => 'शहर';

  @override
  String get state => 'राज्य';

  @override
  String get country => 'देश';

  @override
  String get zipCode => 'पिन कोड';

  @override
  String get description => 'विवरण';

  @override
  String get date => 'तारीख';

  @override
  String get time => 'समय';

  @override
  String get duration => 'अवधि';

  @override
  String get price => 'मूल्य';

  @override
  String get cost => 'लागत';

  @override
  String get total => 'कुल';

  @override
  String get amount => 'राशि';

  @override
  String get payment => 'भुगतान';

  @override
  String get paid => 'भुगतान किया';

  @override
  String get pending => 'लंबित';

  @override
  String get completed => 'पूर्ण';

  @override
  String get cancelled => 'रद्द';

  @override
  String get accepted => 'स्वीकार किया';

  @override
  String get rejected => 'अस्वीकार किया';

  @override
  String get inProgress => 'प्रगति में';

  @override
  String get finished => 'समाप्त';

  @override
  String get available => 'उपलब्ध';

  @override
  String get unavailable => 'अनुपलब्ध';

  @override
  String get online => 'ऑनलाइन';

  @override
  String get offline => 'ऑफलाइन';

  @override
  String get active => 'सक्रिय';

  @override
  String get inactive => 'निष्क्रिय';

  @override
  String get enabled => 'सक्षम';

  @override
  String get disabled => 'अक्षम';

  @override
  String get required => 'आवश्यक';

  @override
  String get optional => 'वैकल्पिक';

  @override
  String get yesNoDialogTitle => 'पुष्टि';

  @override
  String get yesNoDialogContent =>
      'क्या आप निश्चित हैं कि आप आगे बढ़ना चाहते हैं?';

  @override
  String get languageChangeDialogTitle => 'भाषा बदलें';

  @override
  String languageChangeDialogContent(Object language) {
    return 'क्या आप निश्चित हैं कि आप भाषा को $language में बदलना चाहते हैं? ऐप रीस्टार्ट हो जाएगा।';
  }

  @override
  String get logoutConfirmationTitle => 'लॉग आउट';

  @override
  String get logoutConfirmationContent =>
      'Kya aap sach mein logout karna chahte hain?';

  @override
  String get locationPermissionTitle => 'स्थान अनुमति';

  @override
  String get locationPermissionContent =>
      'नौकरियों को दूरी के अनुसार फ़िल्टर करने के लिए स्थान अनुमतियां आवश्यक हैं।';

  @override
  String get notificationPermissionTitle => 'सूचना अनुमति';

  @override
  String get notificationPermissionContent =>
      'नौकरी अलर्ट प्राप्त करने के लिए पुश सूचनाएं आवश्यक हैं।';

  @override
  String get appPreferences => 'ऐप प्राथमिकताएं';

  @override
  String get pushNotifications => 'पुश सूचनाएं';

  @override
  String get notificationsEnabled => 'सूचनाएं सक्षम हैं';

  @override
  String get notificationsDisabled =>
      'सूचनाएं अक्षम हैं। सेटिंग्स खोलने के लिए टैप करें।';

  @override
  String get locationServices => 'स्थान सेवाएं';

  @override
  String get locationServicesInfo =>
      'स्थान अनुमति स्वचालित रूप से प्रबंधित की जाती है। यदि अस्वीकार किया जाता है, तो हम बेहतर सेवा मिलान के लिए पहले संग्रहीत स्थान विवरण का उपयोग करते हैं।';

  @override
  String get myServices => 'Meri Services';

  @override
  String get addService => 'Service Add karo';

  @override
  String distanceRange(Object range) {
    return 'दूरी रेंज: $range किमी';
  }

  @override
  String get nearbyJobs => 'नजदीकी नौकरियां';

  @override
  String get noNearbyJobs => 'कोई नजदीकी नौकरियां उपलब्ध नहीं।';

  @override
  String get noMatchingJobs => 'कोई मिलान नौकरियां नहीं।';

  @override
  String get acceptedJobs => 'स्वीकार की गई नौकरियां';

  @override
  String earningsAmount(Object amount) {
    return '₹$amount';
  }

  @override
  String bookingDateTime(Object date, Object time) {
    return 'तारीख: $date\nसमय: $time';
  }

  @override
  String bookingDetails(Object name, Object phone) {
    return 'नाम: $name, मोबाइल: $phone';
  }

  @override
  String get bookingAccepted => 'Booking accept ho gaya!';

  @override
  String errorAcceptingBooking(Object error) {
    return 'बुकिंग स्वीकार करने में त्रुटि: $error';
  }

  @override
  String get checkingStatus => 'स्थिति जांच रहा है...';

  @override
  String get tapToOpenSettings => 'सेटिंग्स खोलने के लिए टैप करें।';

  @override
  String get genieOnCallAgent => 'जीन ऑन कॉल - एजेंट';

  @override
  String get agentUser => 'एजेंट यूजर';

  @override
  String get customer => 'ग्राहक';

  @override
  String get notProvided => 'प्रदान नहीं किया';

  @override
  String get locationNotAvailable => 'स्थान उपलब्ध नहीं';

  @override
  String get timeNotSpecified => 'समय निर्दिष्ट नहीं';

  @override
  String get unknownService => 'अज्ञात सेवा';

  @override
  String get running => 'चल रहा है';

  @override
  String get noServicesAvailable => 'कोई सेवाएं उपलब्ध नहीं।';

  @override
  String get noBookingsAvailable => 'कोई बुकिंग उपलब्ध नहीं।';

  @override
  String errorGettingLocation(Object error) {
    return 'स्थान प्राप्त करने में त्रुटि: $error';
  }

  @override
  String genericError(Object error) {
    return 'त्रुटि: $error';
  }

  @override
  String get noSubServicesFound => 'इस सेवा के लिए कोई उप-सेवाएं नहीं मिलीं।';

  @override
  String get noSubServicesDefined =>
      'इस सेवा के लिए कोई उप-सेवाएं परिभाषित नहीं।';

  @override
  String get mustBeLoggedIn => 'सेवा बुक करने के लिए आपको लॉग इन होना चाहिए।';

  @override
  String failedToBookService(Object error) {
    return 'सेवा बुक करने में विफल: $error';
  }

  @override
  String get locationPermissionDenied => 'स्थान अनुमति अस्वीकार';

  @override
  String get failedToGetCurrentLocation =>
      'वर्तमान स्थान प्राप्त करने में विफल';

  @override
  String get addImages => 'Images Add karo';

  @override
  String get errorLoadingChats => 'चैट लोड करने में त्रुटि';

  @override
  String get errorLoadingMessages => 'संदेश लोड करने में त्रुटि';

  @override
  String get errorGettingLocationShort => 'स्थान उपलब्ध नहीं';

  @override
  String get bookingAcceptedSnackbar => 'बुकिंग स्वीकार की गई!';

  @override
  String errorAcceptingBookingSnackbar(Object error) {
    return 'बुकिंग स्वीकार करने में त्रुटि: $error';
  }

  @override
  String get noServicesAvailableText => 'कोई सेवाएं उपलब्ध नहीं।';

  @override
  String errorFetchingEarnings(Object error) {
    return 'कमाई प्राप्त करने में त्रुटि: $error';
  }

  @override
  String get noEarningsYet => 'अभी तक कोई कमाई नहीं।';

  @override
  String get bookingFinishedAndEarningsUpdated =>
      'बुकिंग समाप्त और कमाई अपडेट की गई!';

  @override
  String errorFinishingBooking(Object error) {
    return 'बुकिंग समाप्त करने में त्रुटि: $error';
  }

  @override
  String get locationNotAvailableShort => 'स्थान उपलब्ध नहीं';

  @override
  String get couldNotLaunchMaps => 'मैप ऐप लॉन्च नहीं कर सका';

  @override
  String get newNotification => 'नई सूचना';

  @override
  String get view => 'देखें';

  @override
  String get selectRole => 'अपनी भूमिका चुनें';

  @override
  String get user => 'उपयोगकर्ता';

  @override
  String get agent => 'एजेंट';

  @override
  String continueAs(Object role) {
    return '$role के रूप में जारी रखें';
  }

  @override
  String get enterPhoneNumber => 'Phone number daalo';

  @override
  String get phoneNumber => 'फोन नंबर';

  @override
  String get sendOTP => 'OTP bhejo';

  @override
  String get enterOTP => 'OTP daalo';

  @override
  String get verifyOTP => 'OTP verify karo';

  @override
  String get invalidOTP => 'अमान्य OTP';

  @override
  String otpSent(Object phone) {
    return '$phone पर OTP भेजा गया';
  }

  @override
  String get resendOTP => 'OTP resend karo';

  @override
  String get otpResent => 'OTP पुनः भेजा गया';

  @override
  String get loginSuccessful => 'लॉग इन सफल';

  @override
  String loginFailed(Object error) {
    return 'लॉग इन विफल: $error';
  }

  @override
  String get registrationSuccessful => 'पंजीकरण सफल';

  @override
  String registrationFailed(Object error) {
    return 'पंजीकरण विफल: $error';
  }

  @override
  String get selectServices => 'Services Select karo';

  @override
  String get selectAtLeastOneService => 'कृपया कम से कम एक सेवा चुनें';

  @override
  String get serviceSelectionComplete => 'सेवा चयन पूरा';

  @override
  String get enterDetails => 'Details daalo';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get saveProfile => 'Profile save karo';

  @override
  String get profileSaved => 'प्रोफाइल सफलतापूर्वक सेव की गई';

  @override
  String profileSaveFailed(Object error) {
    return 'प्रोफाइल सेव करने में विफल: $error';
  }

  @override
  String get bookingSuccessful => 'बुकिंग सफल';

  @override
  String get bookingFailed => 'बुकिंग विफल';

  @override
  String get paymentSuccessful => 'भुगतान सफल';

  @override
  String get paymentFailed => 'भुगतान विफल';

  @override
  String get bookingConfirmed => 'आपकी बुकिंग की पुष्टि हो गई है';

  @override
  String get bookingConfirmedTitle => 'बुकिंग पुष्टि!';

  @override
  String get bookingConfirmedMessage =>
      'सेवा बुक की गई है, एक कार्यकारी जल्द ही नियुक्त किया जाएगा।';

  @override
  String get okButtonLabel => 'Theek hai';

  @override
  String get selectPaymentMethod => 'भुगतान विधि चुनें';

  @override
  String get chatsWithExecutive => 'कार्यकारी के साथ चैट';

  @override
  String get noChatsYet => 'अभी तक कोई चैट नहीं। एक नई बातचीत शुरू करें।';

  @override
  String get loginRequiredTitle => 'लॉग इन आवश्यक';

  @override
  String get startNewChatTitle => 'नई चैट शुरू करें';

  @override
  String get subjectLabel => 'विषय';

  @override
  String get enterChatSubjectHint => 'Chat subject daalo';

  @override
  String get startButtonLabel => 'शुरू करें';

  @override
  String get missingDetailsTitle => 'गुम विवरण';

  @override
  String get missingDetailsContent => 'कृपया अपना नाम और पता दर्ज करें।';

  @override
  String get selectionRequiredTitle => 'चयन आवश्यक';

  @override
  String get selectionRequiredContent => 'कृपया एक तारीख और समय स्लॉट चुनें।';

  @override
  String get newChat => 'नई चैट';

  @override
  String get agentProfile => 'एजेंट प्रोफाइल';

  @override
  String get manageProfileAndServices =>
      'अपनी प्रोफाइल और सेवाएं प्रबंधित करें';

  @override
  String get incompleteProfileTitle => 'अपूर्ण प्रोफाइल';

  @override
  String get pleaseFillAllFields => 'कृपया सभी फ़ील्ड भरें।';

  @override
  String get servicesOffered => 'प्रस्तुत सेवाएं';

  @override
  String get selectServicesPlaceholder => 'Services select karo';

  @override
  String get yearsOfExperience => 'अनुभव के वर्ष';

  @override
  String get detectingLocation => 'स्थान का पता लगाया जा रहा है...';

  @override
  String locationDisplay(Object lat, Object lng) {
    return 'स्थान: $lat, $lng';
  }

  @override
  String get locationNotDetected => 'स्थान का पता नहीं चला';

  @override
  String get english => 'अंग्रेजी';

  @override
  String get hindi => 'हिंदी';

  @override
  String get telugu => 'तेलुगु';

  @override
  String get tenglish => 'टेंग्लिश';

  @override
  String get hinglish => 'हिंग्लिश';

  @override
  String bookingId(Object id) {
    return 'बुकिंग आईडी: $id';
  }

  @override
  String get serviceProvider => 'सेवा प्रदाता';

  @override
  String get bookingDate => 'बुकिंग तारीख';

  @override
  String get bookingTime => 'बुकिंग समय';

  @override
  String get serviceLocation => 'सेवा स्थान';

  @override
  String get totalAmount => 'कुल राशि';

  @override
  String get paymentMethod => 'भुगतान विधि';

  @override
  String get cashOnDelivery => 'डिलीवरी पर नकद';

  @override
  String get onlinePayment => 'ऑनलाइन भुगतान';

  @override
  String get proceedToPayment => 'भुगतान पर आगे बढ़ें';

  @override
  String get confirmBooking => 'बुकिंग की पुष्टि करें';

  @override
  String get bookingSummary => 'बुकिंग सारांश';

  @override
  String get change => 'बदलें';

  @override
  String get apply => 'लागू करें';

  @override
  String get discount => 'छूट';

  @override
  String get tax => 'कर';

  @override
  String get subtotal => 'उप-योग';

  @override
  String get grandTotal => 'कुल योग';

  @override
  String get termsAndConditions => 'नियम और शर्तें';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get aboutUs => 'हमारे बारे में';

  @override
  String get contactUs => 'हमसे संपर्क करें';

  @override
  String get faq => 'सामान्य प्रश्न';

  @override
  String get helpCenter => 'सहायता केंद्र';

  @override
  String get rateUs => 'हमें रेट करें';

  @override
  String get shareApp => 'ऐप शेयर करें';

  @override
  String get feedback => 'प्रतिक्रिया';

  @override
  String get reportIssue => 'मुद्दा रिपोर्ट करें';

  @override
  String appVersion(Object version) {
    return 'ऐप संस्करण $version';
  }

  @override
  String get developedBy => 'द्वारा विकसित';

  @override
  String get copyright => '© 2024 सभी अधिकार सुरक्षित';

  @override
  String get addressLabel => 'पता : ';

  @override
  String get dateLabel => 'तारीख: ';

  @override
  String get timeLabel => 'समय: ';

  @override
  String get nameLabel => 'नाम: ';

  @override
  String get mobileLabel => 'मोबाइल: ';

  @override
  String get distanceRangeLabel => 'दूरी रेंज: ';

  @override
  String get km => 'किमी';

  @override
  String get descriptionLabel => 'विवरण';

  @override
  String get optionalLabel => 'वैकल्पिक';

  @override
  String get describeService => 'अपनी सेवा आवश्यकताओं का वर्णन करें';

  @override
  String get describeServiceHint =>
      'जैसे, मुझे किचन सिंक के लिए प्लंबिंग चाहिए';

  @override
  String get recordVoice => 'आवाज़ रिकॉर्ड करें';

  @override
  String get stopRecording => 'रिकॉर्डिंग रोकें';

  @override
  String get playRecording => 'रिकॉर्डिंग चलाएँ';

  @override
  String get stopPlayback => 'बंद करें';
}

/// The translations for English (`en_TI`).
class AppLocalizationsEnTi extends AppLocalizationsEn {
  AppLocalizationsEnTi() : super('en_TI');

  @override
  String get appTitle => 'జీనీ ఆన్ కాల్';

  @override
  String get login => 'Login chey';

  @override
  String get logout => 'Logout chey';

  @override
  String get settings => 'సెట్టింగులు';

  @override
  String get home => 'హోమ్';

  @override
  String get myBookings => 'Na Bookings';

  @override
  String get myEarnings => 'Na Sampadana';

  @override
  String get chat => 'చాట్';

  @override
  String get accept => 'Accept chey';

  @override
  String get cancel => 'Cancel chey';

  @override
  String get confirm => 'Confirm chey';

  @override
  String get yes => 'Avunu';

  @override
  String get no => 'Kadhu';

  @override
  String get ok => 'Sare';

  @override
  String get save => 'Save chey';

  @override
  String get delete => 'Delete chey';

  @override
  String get edit => 'Edit chey';

  @override
  String get add => 'Add chey';

  @override
  String get remove => 'Remove chey';

  @override
  String get search => 'Search chey';

  @override
  String get filter => 'ఫిల్టర్';

  @override
  String get sort => 'క్రమబద్ధీకరించు';

  @override
  String get loading => 'లోడ్ అవుతోంది...';

  @override
  String get error => 'లోపం';

  @override
  String get success => 'విజయం';

  @override
  String get warning => 'హెచ్చరిక';

  @override
  String get info => 'Info';

  @override
  String get retry => 'Retry chey';

  @override
  String get back => 'వెనుకకు';

  @override
  String get next => 'తరువాత';

  @override
  String get previous => 'మునుపటి';

  @override
  String get continueButton => 'Continue chey';

  @override
  String get skip => 'దాటవేయు';

  @override
  String get done => 'పూర్తి';

  @override
  String get close => 'మూసివేయు';

  @override
  String get open => 'తెరువు';

  @override
  String get select => 'Select chey';

  @override
  String get choose => 'Choose chey';

  @override
  String get pick => 'Pick chey';

  @override
  String get submit => 'Submit chey';

  @override
  String get send => 'Send chey';

  @override
  String get receive => 'Receive chey';

  @override
  String get welcome => 'స్వాగతం';

  @override
  String get hello => 'హలో';

  @override
  String get goodbye => 'వీడ్కోలు';

  @override
  String get thankYou => 'ధన్యవాదాలు';

  @override
  String get please => 'దయచేసి';

  @override
  String get sorry => 'క్షమించండి';

  @override
  String get help => 'సహాయం';

  @override
  String get support => 'మద్దతు';

  @override
  String get contact => 'సంప్రదించు';

  @override
  String get about => 'గురించి';

  @override
  String get version => 'వెర్షన్';

  @override
  String get language => 'భాష';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get theme => 'థీమ్';

  @override
  String get darkMode => 'డార్క్ మోడ్';

  @override
  String get lightMode => 'లైట్ మోడ్';

  @override
  String get notifications => 'నోటిఫికేషన్లు';

  @override
  String get location => 'స్థానం';

  @override
  String get permissions => 'అనుమతులు';

  @override
  String get services => 'సేవలు';

  @override
  String get bookings => 'బుకింగులు';

  @override
  String get earnings => 'సంపాదన';

  @override
  String get profile => 'ప్రొఫైల్';

  @override
  String get account => 'ఖాతా';

  @override
  String get password => 'పాస్వర్డ్';

  @override
  String get email => 'ఇమెయిల్';

  @override
  String get phone => 'ఫోన్';

  @override
  String get name => 'పేరు';

  @override
  String get address => 'చిరునామా';

  @override
  String get city => 'నగరం';

  @override
  String get state => 'రాష్ట్రం';

  @override
  String get country => 'దేశం';

  @override
  String get zipCode => 'పిన్ కోడ్';

  @override
  String get description => 'వివరణ';

  @override
  String get date => 'తేదీ';

  @override
  String get time => 'సమయం';

  @override
  String get duration => 'వ్యవధి';

  @override
  String get price => 'ధర';

  @override
  String get cost => 'ఖర్చు';

  @override
  String get total => 'మొత్తం';

  @override
  String get amount => 'మొత్తం';

  @override
  String get payment => 'చెల్లింపు';

  @override
  String get paid => 'చెల్లించబడింది';

  @override
  String get pending => 'పెండింగ్';

  @override
  String get completed => 'పూర్తి';

  @override
  String get cancelled => 'రద్దు';

  @override
  String get accepted => 'అంగీకరించబడింది';

  @override
  String get rejected => 'తిరస్కరించబడింది';

  @override
  String get inProgress => 'ప్రోగ్రెస్ లో';

  @override
  String get finished => 'ముగించబడింది';

  @override
  String get available => 'అందుబాటులో';

  @override
  String get unavailable => 'అందుబాటులో లేదు';

  @override
  String get online => 'ఆన్‌లైన్';

  @override
  String get offline => 'ఆఫ్‌లైన్';

  @override
  String get active => 'అక్టివ్';

  @override
  String get inactive => 'ఇన్‌అక్టివ్';

  @override
  String get enabled => 'ఎనేబుల్ చేయబడింది';

  @override
  String get disabled => 'డిసేబుల్ చేయబడింది';

  @override
  String get required => 'అవసరం';

  @override
  String get optional => 'ఐచ్ఛికం';

  @override
  String get yesNoDialogTitle => 'నిర్ధారణ';

  @override
  String get yesNoDialogContent => 'మీరు ముందుకు వెళ్లాలనుకుంటున్నారా?';

  @override
  String get languageChangeDialogTitle => 'భాష మార్చు';

  @override
  String languageChangeDialogContent(Object language) {
    return 'మీరు భాషను $language కు మార్చాలనుకుంటున్నారా? యాప్ రీస్టార్ట్ అవుతుంది.';
  }

  @override
  String get logoutConfirmationTitle => 'లాగౌట్';

  @override
  String get logoutConfirmationContent =>
      'Nuvvu nenu logout avvalani korukuntaava?';

  @override
  String get locationPermissionTitle => 'స్థాన అనుమతి';

  @override
  String get locationPermissionContent =>
      'జాబ్‌లను దూరం ఆధారంగా ఫిల్టర్ చేయడానికి స్థాన అనుమతులు అవసరం.';

  @override
  String get notificationPermissionTitle => 'నోటిఫికేషన్ అనుమతి';

  @override
  String get notificationPermissionContent =>
      'జాబ్ అలర్ట్‌లను స్వీకరించడానికి పుష్ నోటిఫికేషన్లు అవసరం.';

  @override
  String get appPreferences => 'యాప్ ప్రాధాన్యతలు';

  @override
  String get pushNotifications => 'పుష్ నోటిఫికేషన్లు';

  @override
  String get notificationsEnabled => 'నోటిఫికేషన్లు ఎనేబుల్ చేయబడ్డాయి';

  @override
  String get notificationsDisabled =>
      'నోటిఫికేషన్లు డిసేబుల్ చేయబడ్డాయి. సెట్టింగులను తెరవడానికి ట్యాప్ చేయండి.';

  @override
  String get locationServices => 'స్థాన సేవలు';

  @override
  String get locationServicesInfo =>
      'స్థాన అనుమతి ఆటోమేటిక్‌గా మేనేజ్ చేయబడుతుంది. తిరస్కరించినట్లయితే, మేము మెరుగైన సర్వీస్ మ్యాచింగ్ కోసం మునుపు స్టోర్ చేసిన స్థాన వివరాలను ఉపయోగిస్తాము.';

  @override
  String get myServices => 'Na Services';

  @override
  String get addService => 'Service Add chey';

  @override
  String distanceRange(Object range) {
    return 'దూరం పరిధి: $range కిమీ';
  }

  @override
  String get nearbyJobs => 'సమీప జాబ్‌లు';

  @override
  String get noNearbyJobs => 'సమీపంలో జాబ్‌లు అందుబాటులో లేవు.';

  @override
  String get noMatchingJobs => 'మ్యాచింగ్ జాబ్‌లు లేవు.';

  @override
  String get acceptedJobs => 'అంగీకరించబడిన జాబ్‌లు';

  @override
  String earningsAmount(Object amount) {
    return '₹$amount';
  }

  @override
  String bookingDateTime(Object date, Object time) {
    return 'తేదీ: $date\nసమయం: $time';
  }

  @override
  String bookingDetails(Object name, Object phone) {
    return 'పేరు: $name, మొబైల్: $phone';
  }

  @override
  String get bookingAccepted => 'Booking accept aindi!';

  @override
  String errorAcceptingBooking(Object error) {
    return 'బుకింగ్ అంగీకరించడంలో లోపం: $error';
  }

  @override
  String get checkingStatus => 'స్టేటస్ చెక్ చేస్తోంది...';

  @override
  String get tapToOpenSettings => 'సెట్టింగులను తెరవడానికి ట్యాప్ చేయండి.';

  @override
  String get genieOnCallAgent => 'జీనీ ఆన్ కాల్ - ఏజెంట్';

  @override
  String get agentUser => 'ఏజెంట్ యూజర్';

  @override
  String get customer => 'కస్టమర్';

  @override
  String get notProvided => 'ప్రొవైడ్ చేయబడలేదు';

  @override
  String get locationNotAvailable => 'స్థానం అందుబాటులో లేదు';

  @override
  String get timeNotSpecified => 'సమయం స్పెసిఫై చేయబడలేదు';

  @override
  String get unknownService => 'తెలియని సర్వీస్';

  @override
  String get running => 'రన్నింగ్';

  @override
  String get noServicesAvailable => 'సేవలు అందుబాటులో లేవు.';

  @override
  String get noBookingsAvailable => 'బుకింగులు అందుబాటులో లేవు.';

  @override
  String errorGettingLocation(Object error) {
    return 'స్థానం పొందడంలో లోపం: $error';
  }

  @override
  String genericError(Object error) {
    return 'లోపం: $error';
  }

  @override
  String get noSubServicesFound => 'ఈ సర్వీస్ కోసం సబ్ సేవలు కనుగొనబడలేదు.';

  @override
  String get noSubServicesDefined =>
      'ఈ సర్వీస్ కోసం సబ్ సేవలు డిఫైన్ చేయబడలేదు.';

  @override
  String get mustBeLoggedIn => 'సర్వీస్ బుక్ చేయడానికి మీరు లాగిన్ అయి ఉండాలి.';

  @override
  String failedToBookService(Object error) {
    return 'సర్వీస్ బుక్ చేయడంలో విఫలం: $error';
  }

  @override
  String get locationPermissionDenied => 'స్థాన అనుమతి తిరస్కరించబడింది';

  @override
  String get failedToGetCurrentLocation => 'ప్రస్తుత స్థానం పొందడంలో విఫలం';

  @override
  String get addImages => 'Images Add chey';

  @override
  String get errorLoadingChats => 'చాట్‌లను లోడ్ చేయడంలో లోపం';

  @override
  String get errorLoadingMessages => 'మెసేజ్‌లను లోడ్ చేయడంలో లోపం';

  @override
  String get errorGettingLocationShort => 'స్థానం అందుబాటులో లేదు';

  @override
  String get bookingAcceptedSnackbar => 'బుకింగ్ అంగీకరించబడింది!';

  @override
  String errorAcceptingBookingSnackbar(Object error) {
    return 'బుకింగ్ అంగీకరించడంలో లోపం: $error';
  }

  @override
  String get noServicesAvailableText => 'సేవలు అందుబాటులో లేవు.';

  @override
  String errorFetchingEarnings(Object error) {
    return 'సంపాదన పొందడంలో లోపం: $error';
  }

  @override
  String get noEarningsYet => 'ఇంకా సంపాదన లేదు.';

  @override
  String get bookingFinishedAndEarningsUpdated =>
      'బుకింగ్ ముగించబడింది మరియు సంపాదన అప్‌డేట్ చేయబడింది!';

  @override
  String errorFinishingBooking(Object error) {
    return 'బుకింగ్ ముగించడంలో లోపం: $error';
  }

  @override
  String get locationNotAvailableShort => 'స్థానం అందుబాటులో లేదు';

  @override
  String get couldNotLaunchMaps => 'మ్యాప్స్ యాప్ లాంచ్ చేయలేకపోయింది';

  @override
  String get newNotification => 'కొత్త నోటిఫికేషన్';

  @override
  String get view => 'వీక్షించు';

  @override
  String get selectRole => 'మీ పాత్రను ఎంచుకోండి';

  @override
  String get user => 'యూజర్';

  @override
  String get agent => 'ఏజెంట్';

  @override
  String continueAs(Object role) {
    return '$role గా కొనసాగించు';
  }

  @override
  String get enterPhoneNumber => 'Phone number enter chey';

  @override
  String get phoneNumber => 'ఫోన్ నంబర్';

  @override
  String get sendOTP => 'OTP pampu';

  @override
  String get enterOTP => 'OTP enter chey';

  @override
  String get verifyOTP => 'OTP verify chey';

  @override
  String get invalidOTP => 'ఇన్‌వ్యాలిడ్ OTP';

  @override
  String otpSent(Object phone) {
    return '$phone కు OTP పంపబడింది';
  }

  @override
  String get resendOTP => 'OTP resend chey';

  @override
  String get otpResent => 'OTP మళ్లీ పంపబడింది';

  @override
  String get loginSuccessful => 'లాగిన్ విజయవంతం';

  @override
  String loginFailed(Object error) {
    return 'లాగిన్ విఫలం: $error';
  }

  @override
  String get registrationSuccessful => 'రిజిస్ట్రేషన్ విజయవంతం';

  @override
  String registrationFailed(Object error) {
    return 'రిజిస్ట్రేషన్ విఫలం: $error';
  }

  @override
  String get selectServices => 'Services Select chey';

  @override
  String get selectAtLeastOneService => 'దయచేసి కనీసం ఒక సర్వీస్ ఎంచుకోండి';

  @override
  String get serviceSelectionComplete => 'సర్వీస్ సెలెక్షన్ పూర్తి';

  @override
  String get enterDetails => 'Details enter chey';

  @override
  String get fullName => 'పూర్తి పేరు';

  @override
  String get saveProfile => 'Profile save chey';

  @override
  String get profileSaved => 'ప్రొఫైల్ విజయవంతంగా సేవ్ చేయబడింది';

  @override
  String profileSaveFailed(Object error) {
    return 'ప్రొఫైల్ సేవ్ చేయడంలో విఫలం: $error';
  }

  @override
  String get bookingSuccessful => 'బుకింగ్ విజయవంతం';

  @override
  String get bookingFailed => 'బుకింగ్ విఫలం';

  @override
  String get paymentSuccessful => 'చెల్లింపు విజయవంతం';

  @override
  String get paymentFailed => 'చెల్లింపు విఫలం';

  @override
  String get bookingConfirmed => 'మీ బుకింగ్ నిర్ధారించబడింది';

  @override
  String get bookingConfirmedTitle => 'బుకింగ్ నిర్ధారించబడింది!';

  @override
  String get bookingConfirmedMessage =>
      'సర్వీస్ బుక్ చేయబడింది, త్వరలో ఒక ఎగ్జిక్యూటివ్ అసైన్ చేయబడతారు.';

  @override
  String get okButtonLabel => 'Sare';

  @override
  String get selectPaymentMethod => 'చెల్లింపు మెథడ్ ఎంచుకోండి';

  @override
  String get chatsWithExecutive => 'ఎగ్జిక్యూటివ్ తో చాట్‌లు';

  @override
  String get noChatsYet =>
      'ఇంకా చాట్‌లు లేవు. కొత్త కన్వర్సేషన్ ప్రారంభించండి.';

  @override
  String get loginRequiredTitle => 'లాగిన్ అవసరం';

  @override
  String get startNewChatTitle => 'కొత్త చాట్ ప్రారంభించు';

  @override
  String get subjectLabel => 'విషయం';

  @override
  String get enterChatSubjectHint => 'Chat subject enter chey';

  @override
  String get startButtonLabel => 'ప్రారంభించు';

  @override
  String get missingDetailsTitle => 'మిస్సింగ్ వివరాలు';

  @override
  String get missingDetailsContent =>
      'దయచేసి మీ పేరు మరియు చిరునామాను ఎంటర్ చేయండి.';

  @override
  String get selectionRequiredTitle => 'సెలెక్షన్ అవసరం';

  @override
  String get selectionRequiredContent =>
      'దయచేసి తేదీ మరియు సమయ స్లాట్ ఎంచుకోండి.';

  @override
  String get newChat => 'కొత్త చాట్';

  @override
  String get agentProfile => 'ఏజెంట్ ప్రొఫైల్';

  @override
  String get manageProfileAndServices =>
      'మీ ప్రొఫైల్ మరియు సేవలను మేనేజ్ చేయండి';

  @override
  String get incompleteProfileTitle => 'ఇన్‌కంప్లీట్ ప్రొఫైల్';

  @override
  String get pleaseFillAllFields => 'దయచేసి అన్ని ఫీల్డ్‌లను ఫిల్ చేయండి.';

  @override
  String get servicesOffered => 'అందించే సేవలు';

  @override
  String get selectServicesPlaceholder => 'Services select chey';

  @override
  String get yearsOfExperience => 'అనుభవ సంవత్సరాలు';

  @override
  String get detectingLocation => 'స్థానం గుర్తించబడుతోంది...';

  @override
  String locationDisplay(Object lat, Object lng) {
    return 'స్థానం: $lat, $lng';
  }

  @override
  String get locationNotDetected => 'స్థానం గుర్తించబడలేదు';

  @override
  String get english => 'ఇంగ్లిష్';

  @override
  String get hindi => 'హిందీ';

  @override
  String get telugu => 'తెలుగు';

  @override
  String get tenglish => 'టెంగ్లిష్';

  @override
  String get hinglish => 'హింగ్లిష్';

  @override
  String bookingId(Object id) {
    return 'బుకింగ్ ఐడీ: $id';
  }

  @override
  String get serviceProvider => 'సర్వీస్ ప్రొవైడర్';

  @override
  String get bookingDate => 'బుకింగ్ తేదీ';

  @override
  String get bookingTime => 'బుకింగ్ సమయం';

  @override
  String get serviceLocation => 'సర్వీస్ స్థానం';

  @override
  String get totalAmount => 'మొత్తం మొత్తం';

  @override
  String get paymentMethod => 'చెల్లింపు మెథడ్';

  @override
  String get cashOnDelivery => 'డెలివరీలో క్యాష్';

  @override
  String get onlinePayment => 'ఆన్‌లైన్ చెల్లింపు';

  @override
  String get proceedToPayment => 'చెల్లింపుకు వెళ్లు';

  @override
  String get confirmBooking => 'బుకింగ్ నిర్ధారించు';

  @override
  String get bookingSummary => 'బుకింగ్ సమ్మరీ';

  @override
  String get change => 'మార్చు';

  @override
  String get apply => 'అప్లై చేయు';

  @override
  String get discount => 'డిస్కౌంట్';

  @override
  String get tax => 'ట్యాక్స్';

  @override
  String get subtotal => 'సబ్‌టోటల్';

  @override
  String get grandTotal => 'గ్రాండ్ టోటల్';

  @override
  String get termsAndConditions => 'నిబంధనలు మరియు షరతులు';

  @override
  String get privacyPolicy => 'ప్రైవసీ పాలసీ';

  @override
  String get aboutUs => 'మా గురించి';

  @override
  String get contactUs => 'మమ్మల్ని సంప్రదించండి';

  @override
  String get faq => 'తరచుగా అడిగే ప్రశ్నలు';

  @override
  String get helpCenter => 'సహాయ కేంద్రం';

  @override
  String get rateUs => 'మమ్మల్ని రేట్ చేయండి';

  @override
  String get shareApp => 'యాప్ షేర్ చేయండి';

  @override
  String get feedback => 'ఫీడ్‌బ్యాక్';

  @override
  String get reportIssue => 'సమస్యను నివేదించు';

  @override
  String appVersion(Object version) {
    return 'యాప్ వెర్షన్ $version';
  }

  @override
  String get developedBy => 'ద్వారా అభివృద్ధి చేయబడింది';

  @override
  String get copyright => '© 2024 అన్ని హక్కులు సంరక్షితం';

  @override
  String get addressLabel => 'చిరునామా : ';

  @override
  String get dateLabel => 'తేదీ: ';

  @override
  String get timeLabel => 'సమయం: ';

  @override
  String get nameLabel => 'పేరు: ';

  @override
  String get mobileLabel => 'మొబైల్: ';

  @override
  String get distanceRangeLabel => 'దూరం పరిధి: ';

  @override
  String get km => 'కిమీ';

  @override
  String get descriptionLabel => 'వివరణ';

  @override
  String get optionalLabel => 'ఐచ్ఛిక';

  @override
  String get describeService => 'మీ సేవ అవసరాలను వివరించండి';

  @override
  String get describeServiceHint =>
      'ఉదాహరణకు, నాకు కిచెన్ సింక్ కోసం ప్లంబింగ్ అవసరం';

  @override
  String get recordVoice => 'ఆడియో రికార్డ్ చేయండి';

  @override
  String get stopRecording => 'రికార్డింగ్ ఆపు';

  @override
  String get playRecording => 'రికార్డింగ్ నడపండి';

  @override
  String get stopPlayback => 'నివ్వండి';
}
