import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seattle_pulse_mobile/src/core/constants/colors.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_bar.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_button.dart';
import 'package:seattle_pulse_mobile/src/core/widgets/app_input_field.dart';
import 'package:seattle_pulse_mobile/src/features/auth/data/service/user_secure_storage.dart';
import 'package:seattle_pulse_mobile/src/features/setting/provider/user_data_provider.dart';
import 'package:seattle_pulse_mobile/src/features/setting/provider/profile_provider.dart';
import 'package:seattle_pulse_mobile/src/features/setting/screens/widgets/delete_account_dialog.dart';
import 'package:seattle_pulse_mobile/src/features/setting/screens/widgets/tab_button.dart';

final selectedTabProvider = StateProvider<String>((ref) => "Profile");

class SettingScreen extends ConsumerStatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends ConsumerState<SettingScreen> {
  File? _pickedImage;
  final _picker = ImagePicker();

  bool _isProfileSaving = false;
  bool _isAccountSaving = false;
  bool _showHomeLocation = true;

  @override
  void initState() {
    super.initState();
    // Load persisted toggle value
    SecureStorageService.getShowHomeLocation().then((val) {
      setState(() => _showHomeLocation = val);
    });
  }

  Future<void> _pickImage() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) setState(() => _pickedImage = File(xfile.path));
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(selectedTabProvider);
    final userAsync = ref.watch(storedUserProvider);
    final repo = ref.read(profileRepositoryProvider);

    // Controllers inside build() so they're initialized with current user data
    final firstNameController =
        TextEditingController(text: userAsync.value?.firstName ?? '');
    final lastNameController =
        TextEditingController(text: userAsync.value?.lastName ?? '');
    final usernameController =
        TextEditingController(text: userAsync.value?.username ?? '');
    final locationController =
        TextEditingController(text: userAsync.value?.location ?? '');
    final bioController =
        TextEditingController(text: userAsync.value?.bio ?? '');
    final emailController =
        TextEditingController(text: userAsync.value?.email ?? '');
    final phoneController = TextEditingController();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return Scaffold(
      appBar: const CustomAppBar(title: "Settings"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // Avatar + edit button
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColor.colorE2E8F0, width: 2),
                    ),
                    child: CircleAvatar(
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!) as ImageProvider
                          : NetworkImage("https://picsum.photos/id/1/200"),
                      radius: 50,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColor.black,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColor.colorABB0B9, width: 2),
                        ),
                        child: const Icon(Icons.edit_outlined,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Tabs
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColor.colorECF0F5,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ref
                          .read(selectedTabProvider.notifier)
                          .state = "Profile",
                      child: TabButton(
                          title: "Profile",
                          isSelected: selectedTab == "Profile"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ref
                          .read(selectedTabProvider.notifier)
                          .state = "Account",
                      child: TabButton(
                          title: "Account",
                          isSelected: selectedTab == "Account"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ref
                          .read(selectedTabProvider.notifier)
                          .state = "Privacy",
                      child: TabButton(
                          title: "Privacy &\n Security",
                          isSelected: selectedTab == "Privacy"),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // PROFILE TAB
            if (selectedTab == "Profile")
              userAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error: $e")),
                data: (user) => Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColor.colorE2E8F0, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text("First Name", style: _labelStyle),
                        const SizedBox(height: 10),
                        AppInputField(
                          controller: firstNameController,
                          borderRadius: 24,
                          hintText: '',
                          labelText: '',
                          margin: const EdgeInsets.only(bottom: 20),
                        ),
                        Text("Last Name", style: _labelStyle),
                        const SizedBox(height: 10),
                        AppInputField(
                          controller: lastNameController,
                          borderRadius: 24,
                          hintText: '',
                          labelText: '',
                          margin: const EdgeInsets.only(bottom: 20),
                        ),
                        Text("Username", style: _labelStyle),
                        const SizedBox(height: 10),
                        AppInputField(
                          controller: usernameController,
                          isEnabled: true,
                          borderRadius: 24,
                          hintText: '',
                          labelText: '',
                          margin: const EdgeInsets.only(bottom: 20),
                        ),
                        Text("Home Location", style: _labelStyle),
                        const SizedBox(height: 10),
                        AppInputField(
                          controller: locationController,
                          isEnabled: true,
                          borderRadius: 24,
                          hintText: '',
                          labelText: '',
                          margin: const EdgeInsets.only(bottom: 20),
                        ),
                        Text("Bio", style: _labelStyle),
                        const SizedBox(height: 10),
                        AppInputField(
                          controller: bioController,
                          // isMultiLine: true,
                          borderRadius: 24,
                          hintText: '',
                          labelText: '',
                          margin: const EdgeInsets.only(bottom: 20),
                        ),
                        AppButton(
                          borderRadius: 12,
                          isFullWidth: true,
                          isLoading: _isProfileSaving,
                          text: "Save Changes",
                          onPressed: () async {
                            setState(() => _isProfileSaving = true);
                            try {
                              final firstName =
                                  firstNameController.text != user?.firstName
                                      ? firstNameController.text
                                      : null;
                              final lastName =
                                  lastNameController.text != user?.lastName
                                      ? lastNameController.text
                                      : null;
                              final username =
                                  usernameController.text != user?.username
                                      ? usernameController.text
                                      : null;
                              final email = emailController.text != user?.email
                                  ? emailController.text
                                  : null;
                              final originalBio = user?.bio ?? '';
                              final newBio = bioController.text;
                              String? bioParam;
                              if (newBio != originalBio)
                                bioParam = newBio.isEmpty ? null : newBio;
                              final location = locationController.text !=
                                      (user?.location ?? '')
                                  ? locationController.text
                                  : null;

                              final updatedUser = await repo.editProfile(
                                firstName: firstName,
                                lastName: lastName,
                                username: username,
                                email: email,
                                bio: bioParam,
                                location: location,
                                profilePicture: _pickedImage,
                              );

                              // Persist & refresh
                              await SecureStorageService.saveUser(updatedUser);
                              ref.refresh(storedUserProvider);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Profile updated')),
                              );
                            } catch (e, s) {
                              print(s);
                              print(e);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            } finally {
                              setState(() => _isProfileSaving = false);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // PRIVACY TAB
            if (selectedTab == "Privacy")
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                height: 370,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColor.colorE2E8F0,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Text("Security",
                    //     style: TextStyle(
                    //       fontWeight: FontWeight.w500,
                    //       fontSize: 16,
                    //       color: AppColor.black,
                    //     )),
                    // const SizedBox(height: 16),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Display Home Location",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                  color: AppColor.black,
                                )),
                            Switch(
                              value: _showHomeLocation,
                              onChanged: (val) async {
                                try {
                                  final newVal =
                                      await repo.toggleHomeLocation(val);
                                  await SecureStorageService
                                      .saveShowHomeLocation(newVal);
                                  setState(() => _showHomeLocation = newVal);
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              },
                              activeColor: AppColor.black,
                              inactiveThumbColor: AppColor.colorE2E8F0,
                              inactiveTrackColor: AppColor.colorABB0B9,
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                            "Allow others to see your home location in your profile.",
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 16,
                              color: AppColor.color707988,
                            )),
                      ],
                    ),

                    // const SizedBox(height: 46),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Delete Account",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            color: AppColor.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "This action is irreversible and will permanently delete all your data associated with the account.",
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: AppColor.color707988,
                          ),
                        ),
                        const SizedBox(height: 25),
                        AppButton(
                          text: "Delete Account",
                          isFullWidth: true,
                          borderRadius: 12,
                          onPressed: () {
                            showDeleteAccountDialog(context);
                          },
                          backgroundColor: AppColor.colorB81616,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // ACCOUNT TAB
            if (selectedTab == "Account")
              userAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text("Error: $e")),
                data: (user) => Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColor.colorE2E8F0, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text("Email", style: _labelStyle),
                        const SizedBox(height: 10),
                        AppInputField(
                          controller: emailController,
                          borderRadius: 24,
                          hintText: '',
                          labelText: '',
                          margin: const EdgeInsets.only(bottom: 20),
                        ),
                        Text("Phone Number", style: _labelStyle),
                        const SizedBox(height: 10),
                        AppInputField(
                          controller: phoneController,
                          borderRadius: 24,
                          hintText: '',
                          labelText: '',
                          margin: const EdgeInsets.only(bottom: 20),
                        ),
                        Text("Old password", style: _labelStyle),
                        const SizedBox(height: 10),
                        AppInputField(
                          controller: oldPasswordController,
                          isPasswordField: true,
                          obscureText: false,
                          borderRadius: 24,
                          hintText: '',
                          labelText: '',
                          margin: const EdgeInsets.only(bottom: 20),
                        ),
                        Text("New password", style: _labelStyle),
                        const SizedBox(height: 10),
                        AppInputField(
                          controller: newPasswordController,
                          isPasswordField: true,
                          obscureText: false,
                          borderRadius: 24,
                          hintText: '',
                          labelText: '',
                          margin: const EdgeInsets.only(bottom: 20),
                        ),
                        Text("Confirm password", style: _labelStyle),
                        const SizedBox(height: 10),
                        AppInputField(
                          controller: confirmPasswordController,
                          isPasswordField: true,
                          obscureText: false,
                          borderRadius: 24,
                          margin: const EdgeInsets.only(bottom: 20),
                          hintText: '',
                          labelText: '',
                        ),
                        AppButton(
                          borderRadius: 12,
                          isFullWidth: true,
                          isLoading: _isAccountSaving,
                          text: "Save Changes",
                          onPressed: () async {
                            setState(() => _isAccountSaving = true);
                            try {
                              final email = emailController.text != user?.email
                                  ? emailController.text
                                  : null;
                              final updatedUser =
                                  await repo.editProfile(email: email);
                              await SecureStorageService.saveUser(updatedUser);
                              ref.refresh(storedUserProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Account updated')),
                              );
                            } catch (e) {
                              print(e);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            } finally {
                              setState(() => _isAccountSaving = false);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String placeholder,
      {bool isReadOnly = false, bool isMultiLine = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 5),
        TextFormField(
          readOnly: isReadOnly,
          maxLines: isMultiLine ? 3 : 1,
          initialValue: placeholder,
          style: TextStyle(color: AppColor.colorABB0B9, fontSize: 16),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: AppColor.colorABB0B9, width: 4),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Styles
var _labelStyle = TextStyle(
  fontWeight: FontWeight.w400,
  fontSize: 16,
  color: AppColor.black,
);
var _sectionTitleStyle = TextStyle(
  fontWeight: FontWeight.w600,
  fontSize: 17,
  color: AppColor.black,
);
var _sectionDescStyle = TextStyle(
  fontWeight: FontWeight.w400,
  fontSize: 16,
  color: AppColor.color707988,
);
