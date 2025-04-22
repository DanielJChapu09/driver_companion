import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:mymaptest/features/community/view/community_screen.dart';
import 'package:mymaptest/features/navigation/view/saved_places_screen.dart';
import 'package:mymaptest/pages/vehicle_details.dart';
import '../../features/authentication/handler/auth_handler.dart';
import '../../features/authentication/views/email_verification.dart';
import '../../features/authentication/views/email_verification_success.dart';
import '../../features/authentication/views/login_screen.dart';
import '../../features/authentication/views/otp_screen.dart';
import '../../features/authentication/views/resend_reset_email_screen.dart';
import '../../features/authentication/views/sign_up_screen.dart';
import '../../features/community/view/community_map_screen.dart';
import '../../features/community/view/create_notification_screen.dart';
import '../../features/driver_behaviour/view/driver_behavior_screen.dart';
import '../../features/main/pages/mainscreen.dart';
import '../../features/navigation/view/navigation_screen.dart';
import '../../features/navigation/view/search_screen.dart';
import '../../features/service_locator/views/service_locator_screen.dart';
import '../../pages/driver_ai.dart';
import '../../pages/trends.dart';
part 'app_routes.dart';


class AppPages {
  static List<GetPage> routes = [
    GetPage(
      name: Routes.initialScreen,
      page: ()=> const AuthHandler(),
    ),

    GetPage(
      name: Routes.loginScreen,
      page: ()=> const LoginScreen(),
    ),

    GetPage(
        name: Routes.signUpScreen,
        page: ()=> const SignUpScreen(),
    ),

    GetPage(
        name: Routes.resendVerificationEmailScreen,
        page: (){
          final email = Get.arguments as String;
          return ResendResetEmailScreen(email: email,);
        },
    ),


    GetPage(
        name: Routes.emailVerificationScreen,
        page: (){
          final user = Get.arguments as User;
          return EmailVerificationScreen(user: user);
        },
    ),


    GetPage(
        name: Routes.successfulVerificationScreen,
        page: ()=> AccountVerificationSuccessful(),
    ),



    GetPage(
        name: Routes.otpScreen,
        page: ()=> const OTPScreen(),
    ),


    GetPage(
        name: Routes.homeScreen,
        page: ()=> const MainScreen(),
    ),

    GetPage(
        name: Routes.serviceLocator,
        // page: ()=> ServiceLocator(),
        page: ()=> ServiceLocatorScreen(),
    ),

    GetPage(
        name: Routes.driverAIScreen,
        page: ()=> DriverAIScreen(),
    ),

    GetPage(
        name: Routes.community,
        page: ()=> CommunityScreen(),
    ),

    GetPage(
        name: Routes.trends,
        page: ()=> TrendsPage(),
    ),

    GetPage(
        name: Routes.driverBehavior,
        page: ()=> DriverBehaviorScreen(),
    ),


    GetPage(
        name: Routes.createNotificationScreen,
        page: () => CreateNotificationScreen()
    ),

    GetPage(
        name: Routes.communityMapScreen,
        page: () => CommunityMapScreen()
    ),


    GetPage(
        name: Routes.vehicleDetails,
        page: ()=> VehicleDetails(),
    ),

    GetPage(
        name: Routes.searchScreen,
        page: ()=> SearchScreen()
    ),

    GetPage(
        name: Routes.savedPlacesScreen,
        page: ()=> SavedPlacesScreen()
    ),


    GetPage(
        name: Routes.navigationScreen,
        page: ()=> NavigationScreen()
    ),

  ];
}

