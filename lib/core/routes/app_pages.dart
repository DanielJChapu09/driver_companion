import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../features/authentication/handler/auth_handler.dart';
import '../../features/authentication/views/email_verification.dart';
import '../../features/authentication/views/email_verification_success.dart';
import '../../features/authentication/views/login_screen.dart';
import '../../features/authentication/views/otp_screen.dart';
import '../../features/authentication/views/resend_reset_email_screen.dart';
import '../../features/authentication/views/sign_up_screen.dart';
import '../../features/main/pages/mainscreen.dart';
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
  ];
}

