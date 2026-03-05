import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/core/db_helper.dart';
import 'package:to_do_app/core/theme_app.dart';
import 'package:to_do_app/model/user_model.dart';
import 'package:to_do_app/view/intro/Start_Screen.dart';
import 'package:to_do_app/widget/app_snackbar.dart';
import 'package:to_do_app/widget/build_textfield.dart';
import 'package:to_do_app/widget/primary_button.dart';
import 'package:to_do_app/core/sync_service.dart';
import 'package:path_provider/path_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = "";
  String email = "";
  String? userId;
  String? profileImageUrl;
  int taskLeft = 0;
  int taskDone = 0;
  final ImagePicker _picker = ImagePicker();
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    loadUserData();
    loadTaskCounts();
  }

  ImageProvider _getProfileImage() {
    if (profileImageUrl == null || profileImageUrl!.isEmpty) {
      return const AssetImage("assets/images/profile.webp");
    }

    // Check if it's a network URL
    if (profileImageUrl!.startsWith('http')) {
      return NetworkImage(profileImageUrl!);
    }

    // Check if it's a local file path
    if (profileImageUrl!.startsWith('/')) {
      File imageFile = File(profileImageUrl!);
      if (imageFile.existsSync()) {
        return FileImage(imageFile);
      }
    }

    // Fallback to default
    return const AssetImage("assets/images/profile.webp");
  }

  Future<void> loadUserData() async {
    if (userId == null) return;

    // 1. Try local data first (DBHelper & SharedPreferences)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    UserModel? localUser = await DBHelper.getUser(userId!);

    setState(() {
      name = localUser?.name ?? prefs.getString('name') ?? "User";
      email = localUser?.email ?? prefs.getString('email') ?? "";
      profileImageUrl =
          localUser?.imagePath ?? FirebaseAuth.instance.currentUser?.photoURL;
    });

    // 2. Sync from Firestore is handled by SyncService listeners/sync
    SyncService().sync();
  }

  Future<void> loadTaskCounts() async {
    if (userId == null) return;
    try {
      final tasks = await DBHelper.getTasks(userId!);
      setState(() {
        taskLeft = tasks.where((t) => !t.isCompleted).length;
        taskDone = tasks.where((t) => t.isCompleted).length;
      });
    } catch (e) {
      debugPrint("Error loading task counts: $e");
    }
  }

  Future<void> updateProfileName(String newName) async {
    if (newName.trim().isEmpty || userId == null) {
      AppSnackbar.error("Name cannot be empty");
      return;
    }

    try {
      // 1. Update Firebase Auth
      await FirebaseAuth.instance.currentUser?.updateDisplayName(newName);

      // 2. Schedule Firestore sync
      SyncService()
          .sync(); // Or handle user profile specifically in SyncService

      // 3. Update Local
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', newName);

      UserModel? user = await DBHelper.getUser(userId!);
      await DBHelper.saveUser(
        UserModel(
          id: userId!,
          name: newName,
          email: user?.email ?? email,
          imagePath: user?.imagePath ?? profileImageUrl,
        ),
      );

      setState(() {
        name = newName;
      });

      AppSnackbar.success("Name updated successfully");
      debugPrint("Name updated to: $newName");
    } catch (e) {
      debugPrint("Error updating name: $e");
      AppSnackbar.error("Failed to update name: $e");
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    if (oldPassword.isEmpty || newPassword.isEmpty) {
      AppSnackbar.error("Please fill in all fields");
      return;
    }

    if (newPassword.length < 6) {
      AppSnackbar.error("Password must be at least 6 characters");
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        AppSnackbar.error("No user logged in");
        return;
      }

      // Re-authenticate user first
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
      AppSnackbar.success("Password updated successfully");
    } catch (e) {
      debugPrint("Error updating password: $e");
      if (e.toString().contains('wrong-password')) {
        AppSnackbar.error("Old password is incorrect");
      } else {
        AppSnackbar.error("Failed to update password");
      }
    }
  }

  Future<void> _handleImage(XFile? image) async {
    if (image == null || userId == null) return;

    setState(() => isUploading = true);

    try {
      // Copy image to app's local directory
      final directory = await getApplicationDocumentsDirectory();
      final String fileName =
          'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String localPath = '${directory.path}/$fileName';

      // Copy the file
      File imageFile = File(image.path);
      await imageFile.copy(localPath);

      debugPrint("Image saved locally to: $localPath");

      // Update Local Firestore marker
      // SyncService should handle user profile too if needed
      SyncService().sync();

      // Update Local SQLite
      await DBHelper.saveUser(
        UserModel(
          id: userId!,
          name: name,
          email: email,
          imagePath: localPath, // Store local path
        ),
      );

      // Update local preference
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImagePath', localPath);

      setState(() {
        profileImageUrl = localPath;
        isUploading = false;
      });

      AppSnackbar.success("Profile image updated");
    } catch (e) {
      setState(() => isUploading = false);
      debugPrint("Error saving image: $e");
      AppSnackbar.error("Failed to save image");
    }
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image != null) {
      Navigator.pop(context); // Close bottom sheet
      _handleImage(image);
    }
  }

  Future<void> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image != null) {
      Navigator.pop(context); // Close bottom sheet
      _handleImage(image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Profile",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.87),
            fontSize: 20,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    backgroundImage: _getProfileImage(),
                    radius: 45,
                    backgroundColor: Colors.black,
                  ),
                  if (isUploading)
                    Positioned.fill(
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.black.withOpacity(0.5),
                        child: CircularProgressIndicator(
                          color: ThemeApp.primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Center(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Lato',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 17,
                    horizontal: 35,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "$taskLeft Task left",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 17,
                    horizontal: 35,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "$taskDone Task done",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Lato',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Account",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Lato',
                ),
              ),
            ),
            profileItem(
              title: "Change account name",
              icon: Icons.person_2_outlined,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    final nameController = TextEditingController(text: name);

                    return Dialog(
                      backgroundColor: const Color.fromARGB(255, 28, 28, 28),
                      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Change account name",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Divider(color: Colors.white),
                              const SizedBox(height: 20),
                              BuildTextFormField(
                                controller: nameController,
                                hintText: "Enter your name",
                                text: 'Username',
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        "Cancel",
                                        style: TextStyle(
                                          color: ThemeApp.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: primaryButton(
                                      text: "Edit",
                                      onTap: () {
                                        if (nameController.text
                                            .trim()
                                            .isNotEmpty) {
                                          updateProfileName(
                                            nameController.text.trim(),
                                          );
                                          Navigator.pop(context);
                                        } else {
                                          AppSnackbar.error(
                                            "Name cannot be empty",
                                          );
                                        }
                                      },
                                      context: context,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            profileItem(
              title: "Change password",
              icon: Icons.lock,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    final oldPasswordController = TextEditingController();
                    final newPasswordController = TextEditingController();

                    return Dialog(
                      backgroundColor: const Color.fromARGB(255, 28, 28, 28),
                      insetPadding: EdgeInsets.symmetric(horizontal: 24),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Change account Password",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Divider(color: Colors.white),
                              SizedBox(height: 20),
                              BuildTextFormField(
                                controller: oldPasswordController,
                                hintText: "Enter old password",
                                text: 'Old Password',
                                obscureText: true,
                              ),
                              BuildTextFormField(
                                controller: newPasswordController,
                                hintText: "Enter new password",
                                text: 'New Password',
                                obscureText: true,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      child: Text(
                                        "Cancel",
                                        style: TextStyle(
                                          color: ThemeApp.primaryColor,
                                        ),
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: primaryButton(
                                      text: "Edit",
                                      onTap: () {
                                        changePassword(
                                          oldPasswordController.text,
                                          newPasswordController.text,
                                        );
                                        Navigator.pop(context);
                                      },
                                      context: context,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            profileItem(
              title: "Change account Image",
              icon: Icons.camera_alt_outlined,
              onTap: () {
                showModalBottomSheet(
                  backgroundColor: const Color.fromARGB(255, 28, 28, 28),
                  context: context,
                  builder: (context) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 24),
                        Text(
                          "Change account Image",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(color: Colors.white),
                        ),
                        SizedBox(height: 16),
                        ListTile(
                          onTap: pickImage,
                          leading: Icon(Icons.photo, color: Colors.white),
                          title: Text(
                            'Choose from Gallery',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                          ),
                          title: Text(
                            'Take a photo',
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: pickImageFromCamera,
                        ),
                        SizedBox(height: 60),
                      ],
                    );
                  },
                );
              },
            ),
            profileItem(
              title: "Logout",
              icon: Icons.logout,
              onTap: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);
                await prefs.remove('userId');
                await DBHelper.clearAllData();
                await FirebaseAuth.instance.signOut();
                Get.offAll(() => const StartScreen());
              },
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Container profileItem({
    String? title,
    IconData? icon,
    GestureTapCallback? onTap,
    Color? color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24),
      margin: EdgeInsets.only(bottom: 10),
      child: ListTile(
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        selectedColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: color ?? Colors.white),
        trailing: color == null
            ? Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.87),
              )
            : null,
        title: Text(
          title!,
          style: TextStyle(
            color: color ?? Colors.white.withValues(alpha: 0.87),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            fontFamily: 'Lato',
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
