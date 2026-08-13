import 'dart:io';

import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:get/get.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart' as p;
import 'package:biblebookapp/core/image_picker_mixin.dart';
import 'package:biblebookapp/core/notifiers/auth/auth.notifier.dart';
import 'package:biblebookapp/core/notifiers/cache.notifier.dart';
import 'package:biblebookapp/core/string_extensions.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/screens/authenitcation/widgets/text_form_field.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:biblebookapp/view/screens/profile/bloc/edit_profile_bloc.dart';
import 'package:biblebookapp/view/screens/profile/bloc/user_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

void confirmDeleteAccount(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      double screenWidth = MediaQuery.of(context).size.width;
      return Dialog(
          backgroundColor: CommanColor.white,
          insetPadding:
              screenWidth > 450 ? EdgeInsets.symmetric(horizontal: 150) : null,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 16,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Are you sure you want to delete your account? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: CommanStyle.black16500
                      .copyWith(fontSize: screenWidth > 450 ? 17 : null),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final cacheprovider =
                        p.Provider.of<AuthNotifier>(context, listen: false);

                    await cacheprovider.deleteyouraccount(context);

                    // FirebaseAuth.instance.currentUser?.delete();
                    // FirebaseAuth.instance.signOut();
                    //  Constants.showToast('Account has been deleted');
                  },
                  child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: CommanColor.lightModePrimary,
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                      ),
                      child: Text(
                        'Delete Now',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            letterSpacing: BibleInfo.letterSpacing,
                            fontSize: screenWidth > 450
                                ? BibleInfo.fontSizeScale * 19
                                : BibleInfo.fontSizeScale * 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      )),
                ),
                const SizedBox(height: 17),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: CommanColor.lightGrey1,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5)),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 2)
                        ],
                      ),
                      child: Text(
                        'Cancel',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            letterSpacing: BibleInfo.letterSpacing,
                            fontSize: screenWidth > 450
                                ? BibleInfo.fontSizeScale * 19
                                : BibleInfo.fontSizeScale * 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black),
                      )),
                )
              ],
            ),
          ));
    },
  );
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen>
    with ImagePickerMixin {
  String? user1 = '';
  String? email = '';
  String? photoUrl;
  bool isLoading = false;
  XFile? pickedImage;
  /// Selected avatar asset path (also sent as profile_image on update).
  String? selectedAvatarAsset;

  static const List<String> _avatarAssets = [
    'assets/avatar png/woman.png',
    'assets/avatar png/man.png',
    'assets/avatar png/cat.png',
    'assets/avatar png/panda.png',
    'assets/avatar png/bear.png',
    'assets/avatar png/chicken.png',
  ];

  late TextEditingController emailCon;
  late TextEditingController nameCon;
// late TextEditingController phoneCon;
  late TextEditingController addressCon;

  Future<void> _showProfilePhotoOptions() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: CommanColor.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    Icons.face_retouching_natural_outlined,
                    color: CommanColor.lightDarkPrimary200(ctx),
                  ),
                  title: const Text('Avatar'),
                  onTap: () => Navigator.of(ctx).pop('avatar'),
                ),
                ListTile(
                  leading: Icon(
                    Icons.photo_library_outlined,
                    color: CommanColor.lightDarkPrimary200(ctx),
                  ),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.of(ctx).pop('gallery'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || choice == null) return;
    if (choice == 'gallery') {
      final profileImage = await getImageFiles();
      if (profileImage != null && mounted) {
        setState(() {
          pickedImage = profileImage;
          selectedAvatarAsset = null;
        });
      }
      return;
    }
    if (choice == 'avatar') {
      await _showAvatarPicker();
    }
  }

  Future<void> _showAvatarPicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: CommanColor.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Choose an avatar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: CommanColor.Blackwhite(ctx),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _avatarAssets.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                  ),
                  itemBuilder: (_, index) {
                    final asset = _avatarAssets[index];
                    final isSelected = selectedAvatarAsset == asset;
                    return GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(asset),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: isSelected ? 3 : 1.5,
                            color: isSelected
                                ? CommanColor.lightDarkPrimary200(ctx)
                                : Colors.grey.shade300,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          asset,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    setState(() {
      selectedAvatarAsset = selected;
      pickedImage = null;
    });
  }

  /// Gallery file or avatar asset → temp file for profile_image upload.
  Future<File?> _resolveProfileImageFile() async {
    if (pickedImage != null) {
      final file = File(pickedImage!.path);
      if (await file.exists()) return file;
    }
    final asset = selectedAvatarAsset?.trim();
    if (asset == null || asset.isEmpty) return null;
    try {
      final data = await rootBundle.load(asset);
      final bytes = data.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final name = asset.split('/').last;
      final file = File('${dir.path}/profile_avatar_$name');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (e) {
      debugPrint('avatar → profile_image file failed: $e');
      return null;
    }
  }

  checkuserloggedin(context) async {
    setState(() {
      isLoading = true;
    });
    final cacheprovider = p.Provider.of<CacheNotifier>(context, listen: false);
    final data = await cacheprovider.readCache(key: 'user');
    final dataname = await cacheprovider.readCache(key: 'name');
    String? datac = await cacheprovider.readCache(key: 'country');
    debugPrint('name is $dataname');
    setState(() {
      isLoading = false;
      // Existing Firebase photo (if any) — display only; upload path unchanged.
      photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
      if (dataname != null) {
        user1 = dataname;
        nameCon.text = user1.toString();
      } else {
        // Clear name field if cache is empty (account deleted)
        user1 = '';
        nameCon.clear();
      }

      if (data != null && dataname != null) {
        email = data;
        emailCon.text = email.toString();
      } else {
        // Clear email field if cache is empty (account deleted)
        email = '';
        emailCon.clear();
      }

      if (datac != null) {
        addressCon.text = datac;
      } else {
        // Clear address field if cache is empty
        addressCon.clear();
      }
    });
  }

  @override
  void initState() {
    emailCon = TextEditingController();
    nameCon = TextEditingController();
    addressCon = TextEditingController();
    checkuserloggedin(context);
    super.initState();
  }

  @override
  void dispose() {
    emailCon.dispose();
    nameCon.dispose();
    addressCon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration:
                p.Provider.of<ThemeProvider>(context).currentCustomTheme ==
                        AppCustomTheme.vintage
                    ? BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage(Images.bgImage(context)),
                            fit: BoxFit.fill))
                    : null,
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator.adaptive(),
                  )
                : Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      children: [
                        const SafeArea(
                          child: SizedBox(
                            height: 12,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Get.back();
                                },
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 15.0),
                                    child: Icon(
                                      Icons.arrow_back_ios,
                                      size: 20,
                                      color: CommanColor.whiteBlack(context),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                                flex: 2,
                                child: Text("Profile",
                                    textAlign: TextAlign.center,
                                    style: CommanStyle.appBarStyle(context))),
                            const Expanded(child: SizedBox.shrink())
                          ],
                        ),
                        const SizedBox(height: 32),
                        Expanded(
                            child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      await _showProfilePhotoOptions();
                                    },
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          clipBehavior: Clip.hardEdge,
                                          foregroundDecoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  width: 2,
                                                  color: CommanColor
                                                      .lightDarkPrimary200(
                                                          context))),
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  width: 2,
                                                  color: CommanColor
                                                      .lightDarkPrimary200(
                                                          context))),
                                          child: pickedImage != null
                                              ? Image.file(
                                                  File(pickedImage!.path),
                                                  height: 110,
                                                  width: 110,
                                                  fit: BoxFit.cover,
                                                )
                                              : selectedAvatarAsset != null
                                                  ? Image.asset(
                                                      selectedAvatarAsset!,
                                                      height: 110,
                                                      width: 110,
                                                      fit: BoxFit.cover,
                                                    )
                                              : (photoUrl != null &&
                                                      photoUrl!.trim().isNotEmpty)
                                                  ? Image.network(
                                                      photoUrl!,
                                                      height: 110,
                                                      width: 110,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                              error,
                                                              stackTrace) =>
                                                          CircleAvatar(
                                                        backgroundColor: CommanColor
                                                                .lightDarkPrimary200(
                                                                    context)
                                                            .withValues(
                                                                alpha: 0.4),
                                                        radius: 50,
                                                        child: Text(
                                                          (user1 != null &&
                                                                  user1!
                                                                      .trim()
                                                                      .isNotEmpty)
                                                              ? (user1!.length >=
                                                                      2
                                                                  ? '${user1![0].toUpperCase()}${user1![1].toUpperCase()}'
                                                                  : user1![0]
                                                                      .toUpperCase())
                                                              : '?',
                                                          style: const TextStyle(
                                                            fontSize: 32,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                              : user1 != null &&
                                                      user1!.trim().isNotEmpty
                                              ? CircleAvatar(
                                                  backgroundColor: CommanColor
                                                          .lightDarkPrimary200(
                                                              context)
                                                      .withValues(
                                                          alpha:
                                                              0.4), // Background color
                                                  radius:
                                                      50, // Adjust size as needed
                                                  child: Text(
                                                    user1!.length >= 2
                                                        ? '${user1![0].toUpperCase()}${user1![1].toUpperCase()}'
                                                        : user1![0]
                                                            .toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 32,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors
                                                          .black, // Text color
                                                    ),
                                                  ),
                                                )
                                              : SizedBox(
                                                  height: 110,
                                                  width: 110,
                                                  child: Center(
                                                    child: Text(
                                                      'N A',
                                                      style: const TextStyle(
                                                          letterSpacing:
                                                              BibleInfo
                                                                  .letterSpacing,
                                                          fontSize: BibleInfo
                                                                  .fontSizeScale *
                                                              24),
                                                    ),
                                                  ),
                                                ),
                                        ),
                                        Positioned(
                                          bottom: -5,
                                          right: 10,
                                          child: Container(
                                            clipBehavior: Clip.hardEdge,
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: CommanColor
                                                  .lightDarkPrimary200(context),
                                            ),
                                            child: Icon(
                                              Icons.camera_alt_outlined,
                                              color: CommanColor.Blackwhite(
                                                  context),
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 48),
                              CustomTextFormField(
                                controller: nameCon,
                                hintText: 'Full Name',
                                validator: FormBuilderValidators.required(
                                    errorText: 'Full Name is required'),
                              ),
                              const SizedBox(height: 20),
                              CustomTextFormField(
                                controller: emailCon,
                                hintText: 'Email',
                              ),
                              const SizedBox(height: 20),
                              CustomTextFormField(
                                controller: addressCon,
                                hintText: 'Country',
                                readOnly: true,
                                onTap: () {
                                  showCountryPicker(
                                    context: context,
                                    showPhoneCode: false,
                                    onSelect: (Country country) {
                                      updateCountry(country);
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 40),
                              GestureDetector(
                                onTap: () async {
                                  final authnotifier =
                                      p.Provider.of<AuthNotifier>(context,
                                          listen: false);

                                  try {
                                    if (emailCon.text.isNotEmpty ||
                                        nameCon.text.isNotEmpty) {
                                      // Existing upload path only — no new save logic.
                                      // Runs before updateprofle (which navigates away).
                                      if (pickedImage != null) {
                                        final editBloc = ProviderScope
                                            .containerOf(context)
                                            .read(editProfileBloc);
                                        editBloc.updateImage(pickedImage);
                                        final firebaseUser =
                                            FirebaseAuth.instance.currentUser;
                                        if (firebaseUser != null) {
                                          await editBloc
                                              .uploadImage(firebaseUser);
                                        }
                                      }
                                      final profileImageFile =
                                          await _resolveProfileImageFile();
                                      print(
                                          'Update Profile Data → gallery=${pickedImage?.path} avatar=$selectedAvatarAsset file=${profileImageFile?.path}');
                                      await authnotifier.updateprofle(
                                          email: emailCon.text.isNotEmpty
                                              ? emailCon.text
                                              : email,
                                          name: nameCon.text.isNotEmpty
                                              ? nameCon.text
                                              : user1,
                                          context: context,
                                          profileImage: profileImageFile);
                                    }
                                  } catch (e) {}
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: CommanColor.isDarkTheme(context)
                                            ? Colors.white
                                            : const Color(0xFF8B5A5A),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Update Profile",
                                        textAlign: TextAlign.center,
                                        style: CommanStyle
                                                .inDarkPrimaryInLightWhite12400(
                                                    context)
                                            .copyWith(
                                          letterSpacing: BibleInfo.letterSpacing,
                                          fontSize:
                                              BibleInfo.fontSizeScale * 16,
                                          color: CommanColor.isDarkTheme(context)
                                              ? Colors.white
                                              : const Color(0xFF8B5A5A),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: () {
                                  confirmDeleteAccount(context);
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: CommanColor.isDarkTheme(context)
                                            ? Colors.white
                                            : const Color(0xFF8B5A5A),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Delete Account",
                                        textAlign: TextAlign.center,
                                        style: CommanStyle
                                                .inDarkPrimaryInLightWhite12400(
                                                    context)
                                            .copyWith(
                                          letterSpacing: BibleInfo.letterSpacing,
                                          fontSize:
                                              BibleInfo.fontSizeScale * 16,
                                          color: CommanColor.isDarkTheme(context)
                                              ? Colors.white
                                              : const Color(0xFF8B5A5A),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                      ],
                    ),
                  ),
          ),
        ));
  }

  updateCountry(Country country) async {
    final cacheprovider = p.Provider.of<CacheNotifier>(context, listen: false);
    debugPrint('Country: $country');

    await cacheprovider.writeCache(
        key: "country", value: '${country.flagEmoji} ${country.name}');

    addressCon.text = '${country.flagEmoji} ${country.name}';
  }
}

class EditProfileScreen1 extends HookConsumerWidget with ImagePickerMixin {
  EditProfileScreen1({super.key});

  String? user1 = '';
  String? email = '';

  checkuserloggedin(context) async {
    final cacheprovider = p.Provider.of<CacheNotifier>(context, listen: false);

    final data = await cacheprovider.readCache(key: 'user');
    final dataname = await cacheprovider.readCache(key: 'name');

    debugPrint(' name is $dataname');

    if (dataname != null) {
      user1 = dataname;
    }

    if (dataname != null) {
      email = data;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    checkuserloggedin(context);
    final user = ref.read(userBloc).user;
    final editProfileState = ref.read(editProfileBloc);

    editProfileState.phoneCon.text = email.toString();
    editProfileState.nameCon.text = user1.toString();

    useMemoized(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        editProfileState.initateUserValue(user);
      });
    });

    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration:
                p.Provider.of<ThemeProvider>(context).currentCustomTheme ==
                        AppCustomTheme.vintage
                    ? BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage(Images.bgImage(context)),
                            fit: BoxFit.fill))
                    : null,
            child: editProfileState.isLoading
                ? const Center(
                    child: CircularProgressIndicator.adaptive(),
                  )
                : Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      children: [
                        const SafeArea(
                          child: SizedBox(
                            height: 12,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Get.back();
                                },
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 15.0),
                                    child: Icon(
                                      Icons.arrow_back_ios,
                                      size: 20,
                                      color: CommanColor.whiteBlack(context),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                                flex: 2,
                                child: Text("Profile",
                                    textAlign: TextAlign.center,
                                    style: CommanStyle.appBarStyle(context))),
                            const Expanded(child: SizedBox.shrink())
                          ],
                        ),
                        const SizedBox(height: 32),
                        Expanded(
                            child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      // final profileImage =
                                      //     await getImageFiles();
                                      // if (profileImage != null) {
                                      //   editProfileState
                                      //       .updateImage(profileImage);
                                      // }
                                    },
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          clipBehavior: Clip.hardEdge,
                                          foregroundDecoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  width: 2,
                                                  color: CommanColor
                                                      .lightDarkPrimary200(
                                                          context))),
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  width: 2,
                                                  color: CommanColor
                                                      .lightDarkPrimary200(
                                                          context))),
                                          child: user1 != null
                                              ? CircleAvatar(
                                                  backgroundColor: CommanColor
                                                          .lightDarkPrimary200(
                                                              context)
                                                      .withOpacity(
                                                          0.4), // Background color
                                                  radius:
                                                      50, // Adjust size as needed
                                                  child: Text(
                                                    user1!.isNotEmpty
                                                        ? user1![0]
                                                            .toUpperCase()
                                                        : '?', // Get first letter
                                                    style: TextStyle(
                                                      fontSize: 32,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors
                                                          .black, // Text color
                                                    ),
                                                  ),
                                                )

                                              //editProfileState.pickedImage ==
                                              //         null
                                              //     ? Image.network(
                                              //         user?.photoURL ?? '',
                                              //         height: 110,
                                              //         width: 110,
                                              //         fit: BoxFit.cover,
                                              //         errorBuilder: (context, error,
                                              //                 stackTrace) =>
                                              //             SizedBox(
                                              //           height: 110,
                                              //           width: 110,
                                              //           child: Center(
                                              //             child: Text(
                                              //               (user?.displayName ??
                                              //                       'N A')
                                              //                   .initials,
                                              //               style: const TextStyle(
                                              //                   letterSpacing:
                                              //                       BibleInfo
                                              //                           .letterSpacing,
                                              //                   fontSize: BibleInfo
                                              //                           .fontSizeScale *
                                              //                       24),
                                              //             ),
                                              //           ),
                                              //         ),
                                              //       )
                                              : Image.file(
                                                  File(editProfileState
                                                      .pickedImage!.path),
                                                  height: 110,
                                                  width: 110,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                          stackTrace) =>
                                                      SizedBox(
                                                    height: 110,
                                                    width: 110,
                                                    child: Center(
                                                      child: Text(
                                                        (user?.displayName ??
                                                                'N A')
                                                            .initials,
                                                        style: const TextStyle(
                                                            letterSpacing:
                                                                BibleInfo
                                                                    .letterSpacing,
                                                            fontSize: BibleInfo
                                                                    .fontSizeScale *
                                                                24),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        ),
                                        // Positioned(
                                        //   bottom: -5,
                                        //   right: 10,
                                        //   child: Container(
                                        //     clipBehavior: Clip.hardEdge,
                                        //     padding: const EdgeInsets.all(4),
                                        //     decoration: BoxDecoration(
                                        //       shape: BoxShape.circle,
                                        //       color: CommanColor
                                        //           .lightDarkPrimary200(context),
                                        //     ),
                                        //     child: Icon(
                                        //       Icons.camera_alt_outlined,
                                        //       color: CommanColor.Blackwhite(
                                        //           context),
                                        //       size: 20,
                                        //     ),
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 48),
                              CustomTextFormField(
                                controller: editProfileState.nameCon,
                                hintText: 'Full Name',
                                validator: FormBuilderValidators.required(
                                    errorText: 'Full Name is required'),
                              ),
                              const SizedBox(height: 20),
                              CustomTextFormField(
                                controller: editProfileState.phoneCon,
                                hintText: 'Email',
                              ),
                              const SizedBox(height: 20),
                              CustomTextFormField(
                                controller: editProfileState.addressCon,
                                hintText: 'Country',
                                readOnly: true,
                                onTap: () {
                                  showCountryPicker(
                                    context: context,
                                    showPhoneCode: false,
                                    onSelect: (Country country) {
                                      editProfileState.updateCountry(country);
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 40),
                              GestureDetector(
                                onTap: () async {
                                  final authnotifier =
                                      p.Provider.of<AuthNotifier>(context,
                                          listen: false);

                                  try {
                                    if (editProfileState
                                            .phoneCon.text.isNotEmpty ||
                                        editProfileState
                                            .nameCon.text.isNotEmpty) {
                                      await authnotifier.updateprofle(
                                          email: editProfileState
                                                  .phoneCon.text.isNotEmpty
                                              ? editProfileState.phoneCon.text
                                              : email,
                                          name: editProfileState
                                                  .nameCon.text.isNotEmpty
                                              ? editProfileState.nameCon.text
                                              : user1,
                                          context: context);
                                      // await editProfileState.updateProfile();
                                      Constants.showToast(
                                          'Profile Updated Successfully');
                                      Get.back();
                                    }
                                  } catch (e) {
                                    Constants.showToast(
                                        'No Internet Connection!');
                                  }
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.circular(3),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black38,
                                          blurRadius: 0.5,
                                          spreadRadius: 1,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                      color: CommanColor.whiteBlack45(context)),
                                  child: Text(
                                    "Update Profile",
                                    textAlign: TextAlign.center,
                                    style: CommanStyle
                                            .inDarkPrimaryInLightWhite12400(
                                                context)
                                        .copyWith(
                                            letterSpacing:
                                                BibleInfo.letterSpacing,
                                            fontSize:
                                                BibleInfo.fontSizeScale * 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: () {
                                  confirmDeleteAccount(context);
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    "Delete Account",
                                    textAlign: TextAlign.center,
                                    style:
                                        CommanStyle
                                                .inDarkPrimaryInLightWhite12400(
                                                    context)
                                            .copyWith(
                                                letterSpacing:
                                                    BibleInfo.letterSpacing,
                                                fontSize:
                                                    BibleInfo.fontSizeScale *
                                                        16,
                                                color: CommanColor.whiteBlack45(
                                                    context)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                      ],
                    ),
                  ),
          ),
        ));
  }
}



// class EditProfileScreen extends HookConsumerWidget with ImagePickerMixin {
//   EditProfileScreen({super.key});

//   String? user1 = '';
//   String? email = '';

//   checkuserloggedin(context) async {
//     final cacheprovider = P.Provider.of<CacheNotifier>(context, listen: false);

//     final data = await cacheprovider.readCache(key: 'user');
//     final dataname = await cacheprovider.readCache(key: 'name');

//     debugPrint(' name is $dataname');

//     if (dataname != null) {
//       user1 = dataname;
//     }

//     if (dataname != null) {
//       email = data;
//     }
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     checkuserloggedin(context);
//     final user = ref.read(userBloc).user;
//     final editProfileState = ref.read(editProfileBloc);

//     editProfileState.phoneCon.text = email.toString();
//     editProfileState.nameCon.text = user1.toString();
//     useMemoized(() {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         editProfileState.initateUserValue(user);
//       });
//     });
//     return Scaffold(
//         resizeToAvoidBottomInset: false,
//         body: GestureDetector(
//           onTap: () {
//             FocusScope.of(context).unfocus();
//           },
//           child: Container(
//             height: MediaQuery.of(context).size.height,
//             width: MediaQuery.of(context).size.width,
//             decoration: BoxDecoration(
//                 image: DecorationImage(
//                     image: AssetImage(Images.bgImage(context)),
//                     fit: BoxFit.fill)),
//             child: editProfileState.isLoading
//                 ? const Center(
//                     child: CircularProgressIndicator.adaptive(),
//                   )
//                 : Padding(
//                     padding: EdgeInsets.only(
//                       bottom: MediaQuery.of(context).viewInsets.bottom,
//                     ),
//                     child: Column(
//                       children: [
//                         const SafeArea(
//                           child: SizedBox(
//                             height: 12,
//                           ),
//                         ),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: InkWell(
//                                 onTap: () {
//                                   Get.back();
//                                 },
//                                 child: Align(
//                                   alignment: Alignment.centerLeft,
//                                   child: Padding(
//                                     padding: const EdgeInsets.only(left: 15.0),
//                                     child: Icon(
//                                       Icons.arrow_back_ios,
//                                       size: 20,
//                                       color: CommanColor.whiteBlack(context),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             Expanded(
//                                 flex: 2,
//                                 child: Text("Profile",
//                                     textAlign: TextAlign.center,
//                                     style: CommanStyle.appBarStyle(context))),
//                             const Expanded(child: SizedBox.shrink())
//                           ],
//                         ),
//                         const SizedBox(height: 32),
//                         Expanded(
//                             child: SingleChildScrollView(
//                           padding: const EdgeInsets.symmetric(horizontal: 24),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.stretch,
//                             children: [
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   GestureDetector(
//                                     onTap: () async {
//                                       // final profileImage =
//                                       //     await getImageFiles();
//                                       // if (profileImage != null) {
//                                       //   editProfileState
//                                       //       .updateImage(profileImage);
//                                       // }
//                                     },
//                                     child: Stack(
//                                       clipBehavior: Clip.none,
//                                       alignment: Alignment.center,
//                                       children: [
//                                         Container(
//                                           clipBehavior: Clip.hardEdge,
//                                           foregroundDecoration: BoxDecoration(
//                                               shape: BoxShape.circle,
//                                               border: Border.all(
//                                                   width: 2,
//                                                   color: CommanColor
//                                                       .lightDarkPrimary200(
//                                                           context))),
//                                           decoration: BoxDecoration(
//                                               shape: BoxShape.circle,
//                                               border: Border.all(
//                                                   width: 2,
//                                                   color: CommanColor
//                                                       .lightDarkPrimary200(
//                                                           context))),
//                                           child: user1 != null
//                                               ? CircleAvatar(
//                                                   backgroundColor: CommanColor
//                                                           .lightDarkPrimary200(
//                                                               context)
//                                                       .withOpacity(
//                                                           0.4), // Background color
//                                                   radius:
//                                                       50, // Adjust size as needed
//                                                   child: Text(
//                                                     user1!.isNotEmpty
//                                                         ? user1![0]
//                                                             .toUpperCase()
//                                                         : '?', // Get first letter
//                                                     style: TextStyle(
//                                                       fontSize: 32,
//                                                       fontWeight:
//                                                           FontWeight.bold,
//                                                       color: Colors
//                                                           .black, // Text color
//                                                     ),
//                                                   ),
//                                                 )

//                                               //editProfileState.pickedImage ==
//                                               //         null
//                                               //     ? Image.network(
//                                               //         user?.photoURL ?? '',
//                                               //         height: 110,
//                                               //         width: 110,
//                                               //         fit: BoxFit.cover,
//                                               //         errorBuilder: (context, error,
//                                               //                 stackTrace) =>
//                                               //             SizedBox(
//                                               //           height: 110,
//                                               //           width: 110,
//                                               //           child: Center(
//                                               //             child: Text(
//                                               //               (user?.displayName ??
//                                               //                       'N A')
//                                               //                   .initials,
//                                               //               style: const TextStyle(
//                                               //                   letterSpacing:
//                                               //                       BibleInfo
//                                               //                           .letterSpacing,
//                                               //                   fontSize: BibleInfo
//                                               //                           .fontSizeScale *
//                                               //                       24),
//                                               //             ),
//                                               //           ),
//                                               //         ),
//                                               //       )
//                                               : Image.file(
//                                                   File(editProfileState
//                                                       .pickedImage!.path),
//                                                   height: 110,
//                                                   width: 110,
//                                                   fit: BoxFit.cover,
//                                                   errorBuilder: (context, error,
//                                                           stackTrace) =>
//                                                       SizedBox(
//                                                     height: 110,
//                                                     width: 110,
//                                                     child: Center(
//                                                       child: Text(
//                                                         (user?.displayName ??
//                                                                 'N A')
//                                                             .initials,
//                                                         style: const TextStyle(
//                                                             letterSpacing:
//                                                                 BibleInfo
//                                                                     .letterSpacing,
//                                                             fontSize: BibleInfo
//                                                                     .fontSizeScale *
//                                                                 24),
//                                                       ),
//                                                     ),
//                                                   ),
//                                                 ),
//                                         ),
//                                         // Positioned(
//                                         //   bottom: -5,
//                                         //   right: 10,
//                                         //   child: Container(
//                                         //     clipBehavior: Clip.hardEdge,
//                                         //     padding: const EdgeInsets.all(4),
//                                         //     decoration: BoxDecoration(
//                                         //       shape: BoxShape.circle,
//                                         //       color: CommanColor
//                                         //           .lightDarkPrimary200(context),
//                                         //     ),
//                                         //     child: Icon(
//                                         //       Icons.camera_alt_outlined,
//                                         //       color: CommanColor.Blackwhite(
//                                         //           context),
//                                         //       size: 20,
//                                         //     ),
//                                         //   ),
//                                         // ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 48),
//                               CustomTextFormField(
//                                 controller: editProfileState.nameCon,
//                                 hintText: 'Full Name',
//                                 validator: FormBuilderValidators.required(
//                                     errorText: 'Full Name is required'),
//                               ),
//                               const SizedBox(height: 20),
//                               CustomTextFormField(
//                                 controller: editProfileState.phoneCon,
//                                 hintText: 'Email',
//                               ),
//                               const SizedBox(height: 20),
//                               CustomTextFormField(
//                                 controller: editProfileState.addressCon,
//                                 hintText: 'Country',
//                                 readOnly: true,
//                                 onTap: () {
//                                   showCountryPicker(
//                                     context: context,
//                                     showPhoneCode: false,
//                                     onSelect: (Country country) {
//                                       editProfileState.updateCountry(country);
//                                     },
//                                   );
//                                 },
//                               ),
//                               const SizedBox(height: 40),
//                               GestureDetector(
//                                 onTap: () async {
//                                   final authnotifier =
//                                       P.Provider.of<AuthNotifier>(context,
//                                           listen: false);

//                                   try {
//                                     if (editProfileState
//                                             .phoneCon.text.isNotEmpty ||
//                                         editProfileState
//                                             .nameCon.text.isNotEmpty) {
//                                       await authnotifier.updateprofle(
//                                           email: editProfileState
//                                                   .phoneCon.text.isNotEmpty
//                                               ? editProfileState.phoneCon.text
//                                               : email,
//                                           name: editProfileState
//                                                   .nameCon.text.isNotEmpty
//                                               ? editProfileState.nameCon.text
//                                               : user1,
//                                           context: context);
//                                       // await editProfileState.updateProfile();
//                                       Constants.showToast(
//                                           'Profile Updated Successfully');
//                                       Get.back();
//                                     }
//                                   } catch (e) {
//                                     Constants.showToast(
//                                         'No Internet Connection!');
//                                   }
//                                 },
//                                 child: Container(
//                                   padding:
//                                       const EdgeInsets.symmetric(vertical: 12),
//                                   decoration: BoxDecoration(
//                                       shape: BoxShape.rectangle,
//                                       borderRadius: BorderRadius.circular(3),
//                                       boxShadow: const [
//                                         BoxShadow(
//                                           color: Colors.black38,
//                                           blurRadius: 0.5,
//                                           spreadRadius: 1,
//                                           offset: Offset(0, 1),
//                                         ),
//                                       ],
//                                       color: CommanColor.whiteBlack45(context)),
//                                   child: Text(
//                                     "Update Profile",
//                                     textAlign: TextAlign.center,
//                                     style: CommanStyle
//                                             .inDarkPrimaryInLightWhite12400(
//                                                 context)
//                                         .copyWith(
//                                             letterSpacing:
//                                                 BibleInfo.letterSpacing,
//                                             fontSize:
//                                                 BibleInfo.fontSizeScale * 16),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(height: 20),
//                               GestureDetector(
//                                 onTap: () {
//                                   confirmDeleteAccount(context);
//                                 },
//                                 child: Container(
//                                   padding:
//                                       const EdgeInsets.symmetric(vertical: 12),
//                                   child: Text(
//                                     "Delete Account",
//                                     textAlign: TextAlign.center,
//                                     style:
//                                         CommanStyle
//                                                 .inDarkPrimaryInLightWhite12400(
//                                                     context)
//                                             .copyWith(
//                                                 letterSpacing:
//                                                     BibleInfo.letterSpacing,
//                                                 fontSize:
//                                                     BibleInfo.fontSizeScale *
//                                                         16,
//                                                 color: CommanColor.whiteBlack45(
//                                                     context)),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ))
//                       ],
//                     ),
//                   ),
//           ),
//         ));
//   }
// }

