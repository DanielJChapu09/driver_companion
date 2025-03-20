import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../widgets/snackbar/custom_snackbar.dart';
import '../services/auth_service.dart';

class AuthController extends GetxController {
  // Reactive variables for state management
  var isLoading = false.obs;
  var currentUser = Rx<User?>(null);
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to FirebaseAuth's user changes
    currentUser.value = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      currentUser.value = user;
    });
  }


  void updateUser(User newUser) {
    currentUser.value = newUser;
  }

  // Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await AuthServices.signUpWithVerification(
        emailAddress: email,
        password: password,
        username: username,
      );

      if (response.success) {
        CustomSnackBar.showSuccessSnackbar(message: response.message!,);
      } else {
        errorMessage.value = response.message!;
        CustomSnackBar.showErrorSnackbar(message: response.message!,);
      }
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  // Login with email and password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await AuthServices.login(
        emailAddress: email,
        password: password,
      );

      if (response.success) {
        CustomSnackBar.showSuccessSnackbar(message:  response.message!,);
      } else {
        errorMessage.value = response.message!;
        CustomSnackBar.showErrorSnackbar(message: response.message!,);
      }
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await AuthServices.signOut();
      if (response.success) {
        CustomSnackBar.showSuccessSnackbar(message: response.message!, );
      } else {
        errorMessage.value = response.message!;
        CustomSnackBar.showErrorSnackbar(message: response.message!,);
      }
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  // Send password reset email
  Future<void> resetPassword({required String email}) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await AuthServices.sendPasswordResetEmail(email: email);
      if (response.success) {
        CustomSnackBar.showSuccessSnackbar(message: response.message!, );
      } else {
        errorMessage.value = response.message!;
        CustomSnackBar.showErrorSnackbar(message: response.message!,);
      }
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  // Update password
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await AuthServices.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (response.success) {
        CustomSnackBar.showSuccessSnackbar(message: response.message!, );
      } else {
        errorMessage.value = response.message!;
        CustomSnackBar.showErrorSnackbar(message: response.message!,);
      }
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }
}
