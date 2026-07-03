import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ta.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ta'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Naam Tamilar Katchi'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get me;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @privacySettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @viewLocation.
  ///
  /// In en, this message translates to:
  /// **'View Location'**
  String get viewLocation;

  /// No description provided for @contactAdmin.
  ///
  /// In en, this message translates to:
  /// **'Contact Admin'**
  String get contactAdmin;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed'**
  String get languageChanged;

  /// No description provided for @reportEmergency.
  ///
  /// In en, this message translates to:
  /// **'Report Emergency'**
  String get reportEmergency;

  /// No description provided for @emergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Title'**
  String get emergencyTitle;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @loadingAlerts.
  ///
  /// In en, this message translates to:
  /// **'Loading alerts...'**
  String get loadingAlerts;

  /// No description provided for @loadingAlertDetail.
  ///
  /// In en, this message translates to:
  /// **'Loading alert...'**
  String get loadingAlertDetail;

  /// No description provided for @alertDetails.
  ///
  /// In en, this message translates to:
  /// **'Alert Details'**
  String get alertDetails;

  /// No description provided for @emergencyTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Emergency title is required'**
  String get emergencyTitleRequired;

  /// No description provided for @locationRequired.
  ///
  /// In en, this message translates to:
  /// **'Location is required'**
  String get locationRequired;

  /// No description provided for @descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get descriptionRequired;

  /// No description provided for @submittingReport.
  ///
  /// In en, this message translates to:
  /// **'Submitting report...'**
  String get submittingReport;

  /// No description provided for @emergencyReported.
  ///
  /// In en, this message translates to:
  /// **'Emergency reported'**
  String get emergencyReported;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @responseSubmited.
  ///
  /// In en, this message translates to:
  /// **'Response submitted'**
  String get responseSubmited;

  /// No description provided for @areYouComing.
  ///
  /// In en, this message translates to:
  /// **'Are you coming?'**
  String get areYouComing;

  /// No description provided for @coming.
  ///
  /// In en, this message translates to:
  /// **'Coming'**
  String get coming;

  /// No description provided for @onTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get onTheWay;

  /// No description provided for @reached.
  ///
  /// In en, this message translates to:
  /// **'Reached'**
  String get reached;

  /// No description provided for @unable.
  ///
  /// In en, this message translates to:
  /// **'Unable'**
  String get unable;

  /// No description provided for @responseSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Response submitted'**
  String get responseSubmitted;

  /// No description provided for @reportDetails.
  ///
  /// In en, this message translates to:
  /// **'Report details'**
  String get reportDetails;

  /// No description provided for @reportedBy.
  ///
  /// In en, this message translates to:
  /// **'Reported by'**
  String get reportedBy;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @noUsersYet.
  ///
  /// In en, this message translates to:
  /// **'No users yet'**
  String get noUsersYet;

  /// No description provided for @contactEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Contact emergency contact'**
  String get contactEmergencyContact;

  /// No description provided for @logoutConfirmText.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmText;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @profileDataNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile data not found'**
  String get profileDataNotFound;

  /// No description provided for @userInformation.
  ///
  /// In en, this message translates to:
  /// **'User Information'**
  String get userInformation;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @memberId.
  ///
  /// In en, this message translates to:
  /// **'Member ID'**
  String get memberId;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get mobileNumber;

  /// No description provided for @approvalStatus.
  ///
  /// In en, this message translates to:
  /// **'Approval Status'**
  String get approvalStatus;

  /// No description provided for @addedBy.
  ///
  /// In en, this message translates to:
  /// **'Added By'**
  String get addedBy;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'coming soon'**
  String get comingSoon;

  /// No description provided for @profileCompletion.
  ///
  /// In en, this message translates to:
  /// **'Profile Completion'**
  String get profileCompletion;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @memberDashboard.
  ///
  /// In en, this message translates to:
  /// **'Member Dashboard'**
  String get memberDashboard;

  /// No description provided for @vanakkam.
  ///
  /// In en, this message translates to:
  /// **'Vanakkam, {name}! 👋'**
  String vanakkam(String name);

  /// No description provided for @todaysHighlights.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Highlights'**
  String get todaysHighlights;

  /// No description provided for @totalMembers.
  ///
  /// In en, this message translates to:
  /// **'Total Members'**
  String get totalMembers;

  /// No description provided for @upcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Events'**
  String get upcomingEvents;

  /// No description provided for @activeAlerts.
  ///
  /// In en, this message translates to:
  /// **'Active Alerts'**
  String get activeAlerts;

  /// No description provided for @broadcasts.
  ///
  /// In en, this message translates to:
  /// **'Broadcasts'**
  String get broadcasts;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @recentUpdates.
  ///
  /// In en, this message translates to:
  /// **'Recent Updates'**
  String get recentUpdates;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @newEventAdded.
  ///
  /// In en, this message translates to:
  /// **'New Event Added'**
  String get newEventAdded;

  /// No description provided for @districtMeetingScheduled.
  ///
  /// In en, this message translates to:
  /// **'District meeting scheduled for this weekend'**
  String get districtMeetingScheduled;

  /// No description provided for @newEventScheduled.
  ///
  /// In en, this message translates to:
  /// **'New Event Scheduled'**
  String get newEventScheduled;

  /// No description provided for @emergencyAlertCreated.
  ///
  /// In en, this message translates to:
  /// **'Emergency Alert Created'**
  String get emergencyAlertCreated;

  /// No description provided for @newBroadcastSent.
  ///
  /// In en, this message translates to:
  /// **'New Broadcast Sent'**
  String get newBroadcastSent;

  /// No description provided for @ntkParty.
  ///
  /// In en, this message translates to:
  /// **'NTK Party'**
  String get ntkParty;

  /// No description provided for @todaysActivity.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Activity'**
  String get todaysActivity;

  /// No description provided for @newMembers.
  ///
  /// In en, this message translates to:
  /// **'New Members'**
  String get newMembers;

  /// No description provided for @registeredToday.
  ///
  /// In en, this message translates to:
  /// **'Registered today'**
  String get registeredToday;

  /// No description provided for @approvedToday.
  ///
  /// In en, this message translates to:
  /// **'Approved Today'**
  String get approvedToday;

  /// No description provided for @totalTowns.
  ///
  /// In en, this message translates to:
  /// **'Total Towns'**
  String get totalTowns;

  /// No description provided for @totalTownsScope.
  ///
  /// In en, this message translates to:
  /// **'Total towns in scope'**
  String get totalTownsScope;

  /// No description provided for @totalStreets.
  ///
  /// In en, this message translates to:
  /// **'Total Streets'**
  String get totalStreets;

  /// No description provided for @totalStreetsScope.
  ///
  /// In en, this message translates to:
  /// **'Total streets in scope'**
  String get totalStreetsScope;

  /// No description provided for @activeEvents.
  ///
  /// In en, this message translates to:
  /// **'Active Events'**
  String get activeEvents;

  /// No description provided for @emergencyRequests.
  ///
  /// In en, this message translates to:
  /// **'Emergency Requests'**
  String get emergencyRequests;

  /// No description provided for @activeBroadcasts.
  ///
  /// In en, this message translates to:
  /// **'Active Broadcasts'**
  String get activeBroadcasts;

  /// No description provided for @subAdmins.
  ///
  /// In en, this message translates to:
  /// **'Sub Admins'**
  String get subAdmins;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'members'**
  String get members;

  /// No description provided for @pendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get pendingRequests;

  /// No description provided for @viewQueue.
  ///
  /// In en, this message translates to:
  /// **'View queue'**
  String get viewQueue;

  /// No description provided for @addSubAdmin.
  ///
  /// In en, this message translates to:
  /// **'Add Sub Admin'**
  String get addSubAdmin;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMember;

  /// No description provided for @broadcast.
  ///
  /// In en, this message translates to:
  /// **'Broadcast'**
  String get broadcast;

  /// No description provided for @event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get event;

  /// No description provided for @reportedPosts.
  ///
  /// In en, this message translates to:
  /// **'Reported Posts'**
  String get reportedPosts;

  /// No description provided for @highPriority.
  ///
  /// In en, this message translates to:
  /// **'{count} High Priority'**
  String highPriority(int count);

  /// No description provided for @pendingReviews.
  ///
  /// In en, this message translates to:
  /// **'Pending Reviews'**
  String get pendingReviews;

  /// No description provided for @totalReports.
  ///
  /// In en, this message translates to:
  /// **'Total Reports'**
  String get totalReports;

  /// No description provided for @subAdminPortal.
  ///
  /// In en, this message translates to:
  /// **'SUB ADMIN PORTAL'**
  String get subAdminPortal;

  /// No description provided for @noPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No Pending Requests'**
  String get noPendingRequests;

  /// No description provided for @membersWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count} Members Waiting'**
  String membersWaiting(int count);

  /// No description provided for @allRequestsProcessed.
  ///
  /// In en, this message translates to:
  /// **'All requests are processed'**
  String get allRequestsProcessed;

  /// No description provided for @tapToReviewAndApprove.
  ///
  /// In en, this message translates to:
  /// **'Tap to review and approve'**
  String get tapToReviewAndApprove;

  /// No description provided for @overviewPartyAdministration.
  ///
  /// In en, this message translates to:
  /// **'Here is an overview of the party administration.'**
  String get overviewPartyAdministration;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @allDistricts.
  ///
  /// In en, this message translates to:
  /// **'All Districts'**
  String get allDistricts;

  /// No description provided for @newMembersMultiLine.
  ///
  /// In en, this message translates to:
  /// **'New\nMembers'**
  String get newMembersMultiLine;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @emergencyAlertsMultiLine.
  ///
  /// In en, this message translates to:
  /// **'Emergency\nAlerts'**
  String get emergencyAlertsMultiLine;

  /// No description provided for @totalAdmins.
  ///
  /// In en, this message translates to:
  /// **'Total Admins'**
  String get totalAdmins;

  /// No description provided for @totalSubAdmins.
  ///
  /// In en, this message translates to:
  /// **'Total Sub Admins'**
  String get totalSubAdmins;

  /// No description provided for @addAdmin.
  ///
  /// In en, this message translates to:
  /// **'Add Admin'**
  String get addAdmin;

  /// No description provided for @addDistrictIncharge.
  ///
  /// In en, this message translates to:
  /// **'Add Dist. Incharge'**
  String get addDistrictIncharge;

  /// No description provided for @emergencyAlert.
  ///
  /// In en, this message translates to:
  /// **'Emergency Alert'**
  String get emergencyAlert;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @accountLabel.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get accountLabel;

  /// No description provided for @updateProfileSub.
  ///
  /// In en, this message translates to:
  /// **'Update your name, photo, and bio'**
  String get updateProfileSub;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @securitySub.
  ///
  /// In en, this message translates to:
  /// **'Change password and 2FA'**
  String get securitySub;

  /// No description provided for @preferencesLabel.
  ///
  /// In en, this message translates to:
  /// **'PREFERENCES'**
  String get preferencesLabel;

  /// No description provided for @notificationsSub.
  ///
  /// In en, this message translates to:
  /// **'Configure alerts and updates'**
  String get notificationsSub;

  /// No description provided for @languageSub.
  ///
  /// In en, this message translates to:
  /// **'Tamil, English'**
  String get languageSub;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceSub.
  ///
  /// In en, this message translates to:
  /// **'Light, Dark, System'**
  String get appearanceSub;

  /// No description provided for @supportLabel.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT'**
  String get supportLabel;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutApp;

  /// No description provided for @broadcastTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Broadcast'**
  String get broadcastTabTitle;

  /// No description provided for @eventsTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsTabTitle;

  /// No description provided for @noEventsScheduled.
  ///
  /// In en, this message translates to:
  /// **'No events scheduled'**
  String get noEventsScheduled;

  /// No description provided for @createEvent.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get createEvent;

  /// No description provided for @eventsList.
  ///
  /// In en, this message translates to:
  /// **'Events List'**
  String get eventsList;

  /// No description provided for @activeUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Active & Upcoming'**
  String get activeUpcoming;

  /// No description provided for @expiredCompleted.
  ///
  /// In en, this message translates to:
  /// **'Expired/Completed'**
  String get expiredCompleted;

  /// No description provided for @noActiveUpcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'No active or upcoming events.'**
  String get noActiveUpcomingEvents;

  /// No description provided for @noExpiredCompletedEvents.
  ///
  /// In en, this message translates to:
  /// **'No expired or completed events.'**
  String get noExpiredCompletedEvents;

  /// No description provided for @failedToLoadBroadcasts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load broadcasts'**
  String get failedToLoadBroadcasts;

  /// No description provided for @createBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Create Broadcast'**
  String get createBroadcast;

  /// No description provided for @emergencyAlerts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Alerts'**
  String get emergencyAlerts;

  /// No description provided for @recentBroadcasts.
  ///
  /// In en, this message translates to:
  /// **'Recent Broadcasts'**
  String get recentBroadcasts;

  /// No description provided for @noEmergencyAlertsFound.
  ///
  /// In en, this message translates to:
  /// **'No emergency alerts found'**
  String get noEmergencyAlertsFound;

  /// No description provided for @noRecentBroadcastsFound.
  ///
  /// In en, this message translates to:
  /// **'No recent broadcasts found'**
  String get noRecentBroadcastsFound;

  /// No description provided for @recallBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Recall Broadcast'**
  String get recallBroadcast;

  /// No description provided for @recallBroadcastConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to recall this broadcast message? This action cannot be undone.'**
  String get recallBroadcastConfirm;

  /// No description provided for @deliveredTo.
  ///
  /// In en, this message translates to:
  /// **'Delivered to'**
  String get deliveredTo;

  /// No description provided for @by.
  ///
  /// In en, this message translates to:
  /// **'By'**
  String get by;

  /// No description provided for @unknownLocation.
  ///
  /// In en, this message translates to:
  /// **'Unknown Location'**
  String get unknownLocation;

  /// No description provided for @unknownTime.
  ///
  /// In en, this message translates to:
  /// **'Unknown Time'**
  String get unknownTime;

  /// No description provided for @forwardToAdmin.
  ///
  /// In en, this message translates to:
  /// **'FORWARD TO ADMIN'**
  String get forwardToAdmin;

  /// No description provided for @forwardToSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'FORWARD TO SUPER ADMIN'**
  String get forwardToSuperAdmin;

  /// No description provided for @approveRequest.
  ///
  /// In en, this message translates to:
  /// **'APPROVE REQUEST'**
  String get approveRequest;

  /// No description provided for @rejectRequest.
  ///
  /// In en, this message translates to:
  /// **'REJECT REQUEST'**
  String get rejectRequest;

  /// No description provided for @forwardRequest.
  ///
  /// In en, this message translates to:
  /// **'FORWARD'**
  String get forwardRequest;

  /// No description provided for @viewResponses.
  ///
  /// In en, this message translates to:
  /// **'VIEW RESPONSES'**
  String get viewResponses;

  /// No description provided for @markAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'MARK AS COMPLETED'**
  String get markAsCompleted;

  /// No description provided for @recallEmergency.
  ///
  /// In en, this message translates to:
  /// **'RECALL EMERGENCY'**
  String get recallEmergency;

  /// No description provided for @responsesOverview.
  ///
  /// In en, this message translates to:
  /// **'Responses Overview'**
  String get responsesOverview;

  /// No description provided for @totalResponses.
  ///
  /// In en, this message translates to:
  /// **'Total Responses'**
  String get totalResponses;

  /// No description provided for @requestInfo.
  ///
  /// In en, this message translates to:
  /// **'Request Info'**
  String get requestInfo;

  /// No description provided for @hospitalDetails.
  ///
  /// In en, this message translates to:
  /// **'Hospital Details'**
  String get hospitalDetails;

  /// No description provided for @locationDetails.
  ///
  /// In en, this message translates to:
  /// **'Location Details'**
  String get locationDetails;

  /// No description provided for @patientDetails.
  ///
  /// In en, this message translates to:
  /// **'Patient Details'**
  String get patientDetails;

  /// No description provided for @requiredSupport.
  ///
  /// In en, this message translates to:
  /// **'Required Support'**
  String get requiredSupport;

  /// No description provided for @contactDetails.
  ///
  /// In en, this message translates to:
  /// **'Contact Details'**
  String get contactDetails;

  /// No description provided for @actionRequired.
  ///
  /// In en, this message translates to:
  /// **'Action Required'**
  String get actionRequired;

  /// No description provided for @joinPrivateGroup.
  ///
  /// In en, this message translates to:
  /// **'Join Private Group'**
  String get joinPrivateGroup;

  /// No description provided for @joinSecretGroup.
  ///
  /// In en, this message translates to:
  /// **'Join Secret Group'**
  String get joinSecretGroup;

  /// No description provided for @provideReason.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for joining this community.'**
  String get provideReason;

  /// No description provided for @enterInviteCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the invite code.'**
  String get enterInviteCode;

  /// No description provided for @yourReason.
  ///
  /// In en, this message translates to:
  /// **'Your reason...'**
  String get yourReason;

  /// No description provided for @inviteCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Invite code...'**
  String get inviteCodeHint;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get sendRequest;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @communityArchivedMessage.
  ///
  /// In en, this message translates to:
  /// **'This community is archived. You can read previous messages, but cannot send new ones.'**
  String get communityArchivedMessage;

  /// No description provided for @joinGroup.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinGroup;

  /// No description provided for @groupsTab.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsTab;

  /// No description provided for @feedTab.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feedTab;

  /// No description provided for @pollsTab.
  ///
  /// In en, this message translates to:
  /// **'Polls'**
  String get pollsTab;

  /// No description provided for @whatIsHappening.
  ///
  /// In en, this message translates to:
  /// **'What is happening in your area?'**
  String get whatIsHappening;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @poll.
  ///
  /// In en, this message translates to:
  /// **'Poll'**
  String get poll;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @requestLocationRoleAccess.
  ///
  /// In en, this message translates to:
  /// **'Request Location / Role Access'**
  String get requestLocationRoleAccess;

  /// No description provided for @myLocationRequests.
  ///
  /// In en, this message translates to:
  /// **'My Location Requests'**
  String get myLocationRequests;

  /// No description provided for @totalDistrictIncharges.
  ///
  /// In en, this message translates to:
  /// **'Dist. Incharges'**
  String get totalDistrictIncharges;

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPost;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @discussion.
  ///
  /// In en, this message translates to:
  /// **'Discussion'**
  String get discussion;

  /// No description provided for @suggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get suggestion;

  /// No description provided for @complaint.
  ///
  /// In en, this message translates to:
  /// **'Complaint'**
  String get complaint;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @writeYourPost.
  ///
  /// In en, this message translates to:
  /// **'Write your post...'**
  String get writeYourPost;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get addPhotos;

  /// No description provided for @communityPost.
  ///
  /// In en, this message translates to:
  /// **'Community Post'**
  String get communityPost;

  /// No description provided for @generalUpdate.
  ///
  /// In en, this message translates to:
  /// **'General Update'**
  String get generalUpdate;

  /// No description provided for @askYourCommunity.
  ///
  /// In en, this message translates to:
  /// **'Ask your community'**
  String get askYourCommunity;

  /// No description provided for @createPollDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a poll for local decisions'**
  String get createPollDescription;

  /// No description provided for @reviewLocationRequests.
  ///
  /// In en, this message translates to:
  /// **'Review Location Requests'**
  String get reviewLocationRequests;

  /// No description provided for @approveRejectLocationChanges.
  ///
  /// In en, this message translates to:
  /// **'Approve or reject role and location changes'**
  String get approveRejectLocationChanges;

  /// No description provided for @recentActivities.
  ///
  /// In en, this message translates to:
  /// **'Recent Activities'**
  String get recentActivities;

  /// No description provided for @createCommunityGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Community Group'**
  String get createCommunityGroup;

  /// No description provided for @createNewGroupDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a new group for your location'**
  String get createNewGroupDesc;

  /// No description provided for @groupDetails.
  ///
  /// In en, this message translates to:
  /// **'Group Details'**
  String get groupDetails;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @privacyType.
  ///
  /// In en, this message translates to:
  /// **'Privacy Type'**
  String get privacyType;

  /// No description provided for @publicAnyoneJoin.
  ///
  /// In en, this message translates to:
  /// **'Public (Anyone can join)'**
  String get publicAnyoneJoin;

  /// No description provided for @privateInviteOnly.
  ///
  /// In en, this message translates to:
  /// **'Private (Invite Only)'**
  String get privateInviteOnly;

  /// No description provided for @membersListTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersListTitle;

  /// No description provided for @searchMembersHint.
  ///
  /// In en, this message translates to:
  /// **'Search members by name or street...'**
  String get searchMembersHint;

  /// No description provided for @filterDistrict.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get filterDistrict;

  /// No description provided for @filterAllDistricts.
  ///
  /// In en, this message translates to:
  /// **'All Districts'**
  String get filterAllDistricts;

  /// No description provided for @filterThoguthi.
  ///
  /// In en, this message translates to:
  /// **'Thoguthi'**
  String get filterThoguthi;

  /// No description provided for @filterAllThoguthis.
  ///
  /// In en, this message translates to:
  /// **'All Thoguthis'**
  String get filterAllThoguthis;

  /// No description provided for @filterArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get filterArea;

  /// No description provided for @filterAllAreas.
  ///
  /// In en, this message translates to:
  /// **'All Areas'**
  String get filterAllAreas;

  /// No description provided for @filterStreet.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get filterStreet;

  /// No description provided for @filterAllStreets.
  ///
  /// In en, this message translates to:
  /// **'All Streets'**
  String get filterAllStreets;

  /// No description provided for @filterRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get filterRole;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterMore.
  ///
  /// In en, this message translates to:
  /// **'More Filters'**
  String get filterMore;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleSubAdmin.
  ///
  /// In en, this message translates to:
  /// **'Sub Admin'**
  String get roleSubAdmin;

  /// No description provided for @roleDistInch.
  ///
  /// In en, this message translates to:
  /// **'Dist. Inch'**
  String get roleDistInch;

  /// No description provided for @roleMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get roleMembers;

  /// No description provided for @roleTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get roleTotal;

  /// No description provided for @memberList.
  ///
  /// In en, this message translates to:
  /// **'Member List'**
  String get memberList;

  /// No description provided for @allowMemberMessages.
  ///
  /// In en, this message translates to:
  /// **'Allow Member Messages'**
  String get allowMemberMessages;

  /// No description provided for @allowMemberMessagesDesc.
  ///
  /// In en, this message translates to:
  /// **'Members can send messages in the group'**
  String get allowMemberMessagesDesc;

  /// No description provided for @notificationCenter.
  ///
  /// In en, this message translates to:
  /// **'Notification Center'**
  String get notificationCenter;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @approvals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get approvals;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get markAllAsRead;

  /// No description provided for @createPollTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Poll'**
  String get createPollTitle;

  /// No description provided for @pollQuestion.
  ///
  /// In en, this message translates to:
  /// **'Poll Question'**
  String get pollQuestion;

  /// No description provided for @enterYourQuestion.
  ///
  /// In en, this message translates to:
  /// **'Enter your question...'**
  String get enterYourQuestion;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @optionIndex.
  ///
  /// In en, this message translates to:
  /// **'Option {index}'**
  String optionIndex(int index);

  /// No description provided for @addOption.
  ///
  /// In en, this message translates to:
  /// **'Add Option'**
  String get addOption;

  /// No description provided for @pollDuration.
  ///
  /// In en, this message translates to:
  /// **'Poll Duration'**
  String get pollDuration;

  /// No description provided for @targetLocation.
  ///
  /// In en, this message translates to:
  /// **'Target Location'**
  String get targetLocation;

  /// No description provided for @street.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get street;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @districtAsterisk.
  ///
  /// In en, this message translates to:
  /// **'District *'**
  String get districtAsterisk;

  /// No description provided for @constituencyTaluk.
  ///
  /// In en, this message translates to:
  /// **'Constituency (Taluk)'**
  String get constituencyTaluk;

  /// No description provided for @areaTown.
  ///
  /// In en, this message translates to:
  /// **'Area (Town)'**
  String get areaTown;

  /// No description provided for @selectStreetOptional.
  ///
  /// In en, this message translates to:
  /// **'Select Street (Optional)'**
  String get selectStreetOptional;

  /// No description provided for @selectState.
  ///
  /// In en, this message translates to:
  /// **'Select State'**
  String get selectState;

  /// No description provided for @selectDistrict.
  ///
  /// In en, this message translates to:
  /// **'Select District'**
  String get selectDistrict;

  /// No description provided for @selectDistrictFirst.
  ///
  /// In en, this message translates to:
  /// **'Select District first'**
  String get selectDistrictFirst;

  /// No description provided for @selectConstituency.
  ///
  /// In en, this message translates to:
  /// **'Select Constituency'**
  String get selectConstituency;

  /// No description provided for @selectConstituencyFirst.
  ///
  /// In en, this message translates to:
  /// **'Select Constituency first'**
  String get selectConstituencyFirst;

  /// No description provided for @selectArea.
  ///
  /// In en, this message translates to:
  /// **'Select Area'**
  String get selectArea;

  /// No description provided for @joinedFilter.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joinedFilter;

  /// No description provided for @featuredFilter.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featuredFilter;

  /// No description provided for @nearbyFilter.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearbyFilter;

  /// No description provided for @communitiesCountText.
  ///
  /// In en, this message translates to:
  /// **'Communities'**
  String get communitiesCountText;

  /// No description provided for @communitySingleText.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communitySingleText;

  /// No description provided for @openAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openAction;

  /// No description provided for @inviteOnly.
  ///
  /// In en, this message translates to:
  /// **'Invite Only'**
  String get inviteOnly;

  /// No description provided for @requestToJoin.
  ///
  /// In en, this message translates to:
  /// **'Request to Join'**
  String get requestToJoin;

  /// No description provided for @joinedStatus.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joinedStatus;

  /// No description provided for @privacyPrivate.
  ///
  /// In en, this message translates to:
  /// **'PRIVATE'**
  String get privacyPrivate;

  /// No description provided for @privacySecret.
  ///
  /// In en, this message translates to:
  /// **'SECRET'**
  String get privacySecret;

  /// No description provided for @privacyPublic.
  ///
  /// In en, this message translates to:
  /// **'PUBLIC'**
  String get privacyPublic;

  /// No description provided for @activityLog.
  ///
  /// In en, this message translates to:
  /// **'Activity Log'**
  String get activityLog;

  /// No description provided for @dashboardActivityLog.
  ///
  /// In en, this message translates to:
  /// **'Dashboard › Activity Log'**
  String get dashboardActivityLog;

  /// No description provided for @admins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get admins;

  /// No description provided for @roleChanges.
  ///
  /// In en, this message translates to:
  /// **'Role Changes'**
  String get roleChanges;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @bloodGroup.
  ///
  /// In en, this message translates to:
  /// **'Blood Group'**
  String get bloodGroup;

  /// No description provided for @profession.
  ///
  /// In en, this message translates to:
  /// **'Profession'**
  String get profession;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @selectAreaFirst.
  ///
  /// In en, this message translates to:
  /// **'Select Area first'**
  String get selectAreaFirst;

  /// No description provided for @selectDistrictOptional.
  ///
  /// In en, this message translates to:
  /// **'Select District (Optional)'**
  String get selectDistrictOptional;

  /// No description provided for @defaultText.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultText;

  /// No description provided for @orSelectSpecificLocation.
  ///
  /// In en, this message translates to:
  /// **'Or select a specific location:'**
  String get orSelectSpecificLocation;

  /// No description provided for @selectStreet.
  ///
  /// In en, this message translates to:
  /// **'Select Street'**
  String get selectStreet;
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
      <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
