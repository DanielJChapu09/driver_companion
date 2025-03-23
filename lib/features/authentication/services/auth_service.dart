import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/utils/api_response.dart';
import '../../../core/utils/logs.dart';

class AuthServices {
  // Sign up with email and password, with email verification
  static Future<APIResponse<User>> signUpWithVerification({
    required String emailAddress,
    required String password,
    required String username,
  }) async {
    try {
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailAddress,
        password: password,
      );

      await userCredential.user!.updateDisplayName(username);
      await userCredential.user!.sendEmailVerification();

      return APIResponse(
          success: true,
          data: userCredential.user,
          message: 'Signup successful. Please verify your email.');
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return APIResponse(
              success: false, message: 'Email Address already in use');
        case 'weak-password':
          return APIResponse(
              success: false, message: 'Your password is too weak');
        default:
          return APIResponse(
              success: false, message: 'Unknown error, please contact Support');
      }
    } catch (e) {
      return APIResponse(
          success: false, message: 'An error occurred. Please try again.');
    }
  }

  // Login with email and password
  static Future<APIResponse<User?>> login({
    required String emailAddress,
    required String password,
  }) async {
    try {
      final UserCredential loginResponse = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: emailAddress, password: password);

      if (loginResponse.user != null) {
        return APIResponse(
            success: true,
            data: loginResponse.user,
            message: 'Login successful');
      } else {
        return APIResponse(
            success: false, message: 'Failed to login. Please try again.');
      }
    } on FirebaseAuthException catch (e) {

      DevLogs.logError(e.toString());
      switch (e.code) {
        case 'invalid-email':
          return APIResponse(
              success: false, message: 'Invalid email address format.');
        case 'user-not-found':
          return APIResponse(
              success: false, message: 'User email not found');
        case 'user-disabled':
          return APIResponse(
              success: false, message: 'User account is disabled.');
        case 'wrong-password':
          return APIResponse(success: false, message: 'Incorrect password.');
        default:
          return APIResponse(
              success: false,
              message: e.message ?? 'An unknown error occurred.');
      }
    } catch (e) {
      return APIResponse(
          success: false, message: 'An error occurred. Please try again.');
    }
  }

  // Sign out user
  static Future<APIResponse<void>> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      return APIResponse(success: true, message: 'Sign out successful');
    } catch (e) {
      return APIResponse(
          success: false, message: 'Failed to sign out. Please try again.');
    }
  }

  // Send password reset email
  static Future<APIResponse<void>> sendPasswordResetEmail(
      {required String email}) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return APIResponse(success: true, message: 'Password reset email sent.');
    } catch (e) {
      return APIResponse(
          success: false,
          message: 'Failed to send password reset email. Please try again.');
    }
  }

  static Future<APIResponse<void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        return APIResponse(success: false, message: 'No user is logged in.');
      }

      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: currentPassword,
      );

      await currentUser.reauthenticateWithCredential(credential);

      // Update the password
      await currentUser.updatePassword(newPassword);

      return APIResponse(
          success: true, message: 'Password updated successfully.');
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          return APIResponse(
              success: false, message: 'Current password is incorrect.');
        case 'weak-password':
          return APIResponse(
              success: false, message: 'New password is too weak.');
        default:
          return APIResponse(
              success: false,
              message: e.message ?? 'Failed to update password.');
      }
    } catch (e) {
      return APIResponse(
          success: false, message: 'An error occurred. Please try again.');
    }
  }

  // static Future<APIResponse<void>> requestVerificationCode({
  //   required String phoneNumber,
  //   required void Function(String verificationId) onCodeSent,
  // }) async {
  //   try {
  //     // Check if the phone number exists in Firestore
  //     final usersRef = FirebaseFirestore.instance.collection('users');
  //     final querySnapshot =
  //         await usersRef.where('phone_number', isEqualTo: phoneNumber).get();
  //
  //     if (querySnapshot.docs.isNotEmpty) {
  //       // Phone number exists, proceed with sending OTP
  //       await FirebaseAuth.instance.verifyPhoneNumber(
  //         phoneNumber: phoneNumber,
  //         verificationCompleted: (PhoneAuthCredential credential) async {
  //           try {
  //             // Automatically sign in the user if the verification is completed
  //             await FirebaseAuth.instance.signInWithCredential(credential);
  //             Get.offAllNamed(RoutesHelper.initialScreen);
  //           } catch (e) {
  //             // Handle any sign-in errors here
  //             Get.snackbar(
  //               'Sign In Error',
  //               'Failed to sign in automatically. Please try again.',
  //               snackPosition: SnackPosition.BOTTOM,
  //             );
  //           }
  //         },
  //         verificationFailed: (FirebaseAuthException error) {
  //           Get.snackbar(
  //             'Verification Failed',
  //             'Verification failed: ${error.message}',
  //             snackPosition: SnackPosition.BOTTOM,
  //           );
  //         },
  //         codeSent: (String verificationId, int? forceResendingToken) {
  //           onCodeSent(
  //               verificationId); // Call the provided callback with verificationId
  //         },
  //         codeAutoRetrievalTimeout: (String verificationId) {
  //           // Handle auto retrieval timeout if needed
  //         },
  //       );
  //       return APIResponse(success: true, message: 'Verification code sent.');
  //     } else {
  //       // Phone number does not exist, show error message
  //       Get.snackbar(
  //         'Phone Number Not Registered',
  //         'Phone number not registered. Please sign up first.',
  //         snackPosition: SnackPosition.BOTTOM,
  //       );
  //       return APIResponse(
  //           success: false, message: 'Phone number not registered.');
  //     }
  //   } catch (e) {
  //     Get.snackbar(
  //       'Error',
  //       'An error occurred: ${e.toString()}',
  //       snackPosition: SnackPosition.BOTTOM,
  //     );
  //     return APIResponse(
  //         success: false, message: 'An error occurred: ${e.toString()}');
  //   }

    // void _handlePhoneNumberSubmit(String phoneNumber) async {
    //   final response = await AuthServices.requestVerificationCode(
    //     phoneNumber: phoneNumber,
    //     onCodeSent: (verificationId) {
    //       Get.to(() => OTPScreen(verificationId: verificationId));
    //     },
    //   );
    //
    //   if (!response.success) {
    //     // Handle the API response error if needed
    //     print(response.message);
    //   }
    // }
  //}
}


