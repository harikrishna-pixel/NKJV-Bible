import 'dart:convert';

import 'package:biblebookapp/services/wallet_service.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:provider/provider.dart';

class PrayerGuidanceScreen extends StatefulWidget {
  const PrayerGuidanceScreen({super.key});

  @override
  State<PrayerGuidanceScreen> createState() => _PrayerGuidanceScreenState();
}

class _PrayerGuidanceScreenState extends State<PrayerGuidanceScreen> {
  static const String _baseUrl =
      'https://my-backend-one-eta.vercel.app/api/gemini';

  final ScrollController _scrollController = ScrollController();
  final List<_GuidanceMessage> _messages = [];
  bool _isLoading = false;
  final TextEditingController _customPrayerController = TextEditingController();

  final List<_GuidanceCategory> _categories = const [
    _GuidanceCategory(
      title: 'Thanksgiving',
      prompt:
          'Write a short prayer of thanksgiving to God. Include 1-2 Geneva Bible verse references.',
    ),
    _GuidanceCategory(
      title: 'Forgiveness',
      prompt:
          'Help me pray for forgiveness and to forgive others. Include 1-2 Geneva Bible verse references.',
    ),
    _GuidanceCategory(
      title: 'Guidance',
      prompt:
          'Give me a prayer asking God for guidance and wisdom for decisions. Include 1-2 Geneva Bible verse references.',
    ),
    _GuidanceCategory(
      title: 'Anxiety & Peace',
      prompt:
          'Give me a prayer for peace when I feel anxious. Include 1-2 Geneva Bible verse references.',
    ),
    _GuidanceCategory(
      title: 'Healing',
      prompt:
          'Give me a prayer for healing (body and heart). Include 1-2 Geneva Bible verse references.',
    ),
    _GuidanceCategory(
      title: 'Family',
      prompt:
          'Give me a prayer for family unity and protection. Include 1-2 Geneva Bible verse references.',
    ),
    _GuidanceCategory(
      title: 'Strength',
      prompt:
          'Give me a prayer for strength and courage during difficult times. Include 1-2 Geneva Bible verse references.',
    ),
    _GuidanceCategory(
      title: 'Protection',
      prompt:
          'Give me a prayer for protection and safety. Include 1-2 Geneva Bible verse references.',
    ),
  ];

  Future<void> _sendPrayerRequest(int categoryIndex) async {
    if (_isLoading) return;

    // Check internet connection
    final isConnected = await InternetConnection().hasInternetAccess;
    if (!isConnected) {
      Constants.showToast("Check Your Internet Connection", 5000);
      return;
    }

    // Credits check (same as Chat)
    final chatCost = await WalletService.getChatCost();
    final hasCredits = await WalletService.getCredits() >= chatCost;
    if (!hasCredits) {
      Constants.showToast('Insufficient credits. Please add credits.', 5000);
      return;
    }

    final category = _categories[categoryIndex];

    setState(() {
      _messages.add(_GuidanceMessage(text: category.title, isUser: true));
      _isLoading = true;
    });

    try {
      final url = Uri.parse(_baseUrl);

      // Answer length instruction (same as ChatScreen idea)
      final answerLength = await WalletService.getAnswerLength();
      String answerLengthInstruction = '';
      switch (answerLength) {
        case 'small':
          answerLengthInstruction =
              'IMPORTANT: Provide a SHORT and concise answer. Keep your response brief (2-3 sentences maximum).';
          break;
        case 'medium':
          answerLengthInstruction =
              'IMPORTANT: Provide a MEDIUM-length answer (4-6 sentences).';
          break;
        case 'large':
          answerLengthInstruction =
              'IMPORTANT: Provide a FULL and comprehensive answer (8+ sentences).';
          break;
        default:
          answerLengthInstruction = 'Provide an appropriate answer.';
      }

      final prompt = '''
You are a respectful assistant for the Geneva Bible. Always respond in plain text without asterisks (*) or markdown.
${answerLengthInstruction}

Task:
${category.prompt}
''';

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      String responseText = 'Sorry, I could not generate a response.';
      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['output'] != null && responseData['output'] is Map) {
            final output = responseData['output'] as Map;
            if (output['candidates'] is List &&
                (output['candidates'] as List).isNotEmpty) {
              final candidate = (output['candidates'] as List)[0];
              if (candidate is Map &&
                  candidate['content'] is Map &&
                  candidate['content']['parts'] is List &&
                  (candidate['content']['parts'] as List).isNotEmpty) {
                final part = (candidate['content']['parts'] as List)[0];
                if (part is Map && part['text'] != null) {
                  responseText = part['text'].toString();
                }
              }
            }
          } else if (responseData['response'] != null) {
            responseText = responseData['response'].toString();
          } else if (responseData['text'] != null) {
            responseText = responseData['text'].toString();
          } else if (responseData['message'] != null) {
            responseText = responseData['message'].toString();
          }
        } catch (_) {}
      } else {
        responseText =
            'Error: Failed to get response (Status: ${response.statusCode})';
      }

      setState(() {
        _messages.add(_GuidanceMessage(text: responseText, isUser: false));
        _isLoading = false;
      });

      // Deduct credits only if we got a non-error response (same behavior as chat)
      final isErrorResponse =
          responseText.toLowerCase().contains('sorry, i could not generate') ||
              responseText.toLowerCase().startsWith('error:');
      if (!isErrorResponse) {
        await WalletService.deductCredits(chatCost);
      }

      _scrollToTop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_GuidanceMessage(
            text: 'Error: Something went wrong. Please try again.',
            isUser: false));
        _isLoading = false;
      });
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendCustomPrayerRequest(String customRequest) async {
    if (_isLoading) return;
    if (customRequest.trim().isEmpty) {
      Constants.showToast("Please enter your prayer request", 3000);
      return;
    }

    // Check internet connection
    final isConnected = await InternetConnection().hasInternetAccess;
    if (!isConnected) {
      Constants.showToast("Check Your Internet Connection", 5000);
      return;
    }

    // Credits check (same as Chat)
    final chatCost = await WalletService.getChatCost();
    final hasCredits = await WalletService.getCredits() >= chatCost;
    if (!hasCredits) {
      Constants.showToast('Insufficient credits. Please add credits.', 5000);
      return;
    }

    setState(() {
      _messages.add(_GuidanceMessage(text: customRequest, isUser: true));
      _isLoading = true;
    });

    try {
      final url = Uri.parse(_baseUrl);

      // Answer length instruction (same as ChatScreen idea)
      final answerLength = await WalletService.getAnswerLength();
      String answerLengthInstruction = '';
      switch (answerLength) {
        case 'small':
          answerLengthInstruction =
              'IMPORTANT: Provide a SHORT and concise answer. Keep your response brief (2-3 sentences maximum).';
          break;
        case 'medium':
          answerLengthInstruction =
              'IMPORTANT: Provide a MEDIUM-length answer (4-6 sentences).';
          break;
        case 'large':
          answerLengthInstruction =
              'IMPORTANT: Provide a FULL and comprehensive answer (8+ sentences).';
          break;
        default:
          answerLengthInstruction = 'Provide an appropriate answer.';
      }

      final prompt = '''
You are a respectful assistant for the Geneva Bible. Always respond in plain text without asterisks (*) or markdown.
${answerLengthInstruction}

Task:
Write a prayer based on the following request: ${customRequest.trim()}
Include 1-2 Geneva Bible verse references that relate to the request.
''';

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      String responseText = 'Sorry, I could not generate a response.';
      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['output'] != null && responseData['output'] is Map) {
            final output = responseData['output'] as Map;
            if (output['candidates'] is List &&
                (output['candidates'] as List).isNotEmpty) {
              final candidate = (output['candidates'] as List)[0];
              if (candidate is Map &&
                  candidate['content'] is Map &&
                  candidate['content']['parts'] is List &&
                  (candidate['content']['parts'] as List).isNotEmpty) {
                final part = (candidate['content']['parts'] as List)[0];
                if (part is Map && part['text'] != null) {
                  responseText = part['text'].toString();
                }
              }
            }
          } else if (responseData['response'] != null) {
            responseText = responseData['response'].toString();
          } else if (responseData['text'] != null) {
            responseText = responseData['text'].toString();
          } else if (responseData['message'] != null) {
            responseText = responseData['message'].toString();
          }
        } catch (_) {}
      } else {
        responseText =
            'Error: Failed to get response (Status: ${response.statusCode})';
      }

      setState(() {
        _messages.add(_GuidanceMessage(text: responseText, isUser: false));
        _isLoading = false;
      });

      // Deduct credits only if we got a non-error response (same behavior as chat)
      final isErrorResponse =
          responseText.toLowerCase().contains('sorry, i could not generate') ||
              responseText.toLowerCase().startsWith('error:');
      if (!isErrorResponse) {
        await WalletService.deductCredits(chatCost);
      }

      _scrollToTop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_GuidanceMessage(
            text: 'Error: Something went wrong. Please try again.',
            isUser: false));
        _isLoading = false;
      });
      _scrollToTop();
    }
  }

  void _showCustomPrayerDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: CommanColor.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Custom Prayer Request',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: CommanColor.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _customPrayerController.clear();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _customPrayerController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Enter your prayer request...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF8B6F47)
                            : const Color(0xFFD4A574),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  style: TextStyle(
                    color: CommanColor.black,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final request = _customPrayerController.text.trim();
                      Navigator.of(context).pop();
                      _customPrayerController.clear();
                      if (request.isNotEmpty) {
                        _sendCustomPrayerRequest(request);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF8B6F47)
                          : const Color(0xFFD4A574),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Send Prayer Request',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF5C4033),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _customPrayerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Images.bgImage(context)),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.arrow_back_ios,
                          color: CommanColor.whiteBlack(context), size: 18),
                    ),
                    Expanded(
                      child: Text(
                        'Prayer Guidance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: CommanColor.whiteBlack(context),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showCustomPrayerDialog(context),
                      icon: Icon(
                        Icons.edit_note,
                        color: CommanColor.whiteBlack(context),
                        size: 24,
                      ),
                      tooltip: 'Custom Prayer Request',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _messages.isEmpty
                    ? SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              'Prayer Guidance',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: CommanColor.whiteBlack(context)
                                    .withOpacity(0.7),
                                fontSize: size.width > 450 ? 26 : 23,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Text(
                                'Get Guidance Based On Your Need...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: CommanColor.whiteBlack(context)
                                      .withOpacity(0.5),
                                  fontSize: size.width > 450 ? 16 : 15,
                                ),
                              ),
                            ),
                            // Category cards in grid - 2 per row, each card triggers AI directly
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: size.width > 450 ? 16 : 12,
                                mainAxisSpacing: size.width > 450 ? 16 : 12,
                                childAspectRatio: size.width > 450 ? 1.4 : 1.3,
                              ),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                // Get icon for each category
                                IconData categoryIcon;

                                switch (index % 8) {
                                  case 0: // Thanksgiving
                                    categoryIcon = Icons.celebration;
                                    break;
                                  case 1: // Forgiving
                                    categoryIcon = Icons.favorite;
                                    break;
                                  case 2: // Guidance
                                    categoryIcon = Icons.lightbulb;
                                    break;
                                  case 3: // Anxiety & Peace
                                    categoryIcon = Icons.self_improvement;
                                    break;
                                  case 4: // Healing
                                    categoryIcon = Icons.healing;
                                    break;
                                  case 5: // Family
                                    categoryIcon = Icons.family_restroom;
                                    break;
                                  case 6: // Strength
                                    categoryIcon = Icons.fitness_center;
                                    break;
                                  default: // Protection
                                    categoryIcon = Icons.shield;
                                    break;
                                }

                                // Old paper/brown color
                                final paperColor = isDark
                                    ? const Color(0xFF8B6F47)
                                    : const Color(0xFFD4A574);

                                return InkWell(
                                  onTap: () {
                                    _sendPrayerRequest(index);
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: size.width > 450 ? 16 : 12,
                                      vertical: size.width > 450 ? 24 : 20,
                                    ),
                                    decoration: BoxDecoration(
                                      color: paperColor,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF6B5638)
                                            : const Color(0xFFB8956A),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          categoryIcon,
                                          size: size.width > 450 ? 32 : 28,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF5C4033),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _categories[index].title,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize:
                                                size.width > 450 ? 17 : 15,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF5C4033),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, idx) {
                          if (_isLoading && idx == _messages.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Please wait...',
                                  style: TextStyle(
                                    color: CommanColor.whiteBlack(context)
                                        .withOpacity(0.7),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }

                          final message = _messages[idx];
                          final isUser = message.isUser;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Align(
                              alignment: isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: size.width * 0.78,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? CommanColor.lightDarkPrimary(context)
                                      : (isDark
                                          ? CommanColor.darkPrimaryColor
                                              .withOpacity(0.6)
                                          : Colors.white.withOpacity(0.85)),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: !isUser && isDark
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: !isUser && isDark ? 1.2 : 0,
                                  ),
                                ),
                                child: Text(
                                  message.text,
                                  style: TextStyle(
                                    fontSize: size.width > 450 ? 18 : 16,
                                    height: 1.5,
                                    color: isUser
                                        ? Colors.white
                                        : CommanColor.whiteBlack(context),
                                    fontWeight: isUser
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // AMEN button at the bottom - only show when there are messages (responses)
              if (_messages.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Constants.showToast("AMEN", 3000);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF8B6F47)
                            : const Color(0xFFD4A574),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'AMEN',
                        style: TextStyle(
                          fontSize: size.width > 450 ? 18 : 16,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white : const Color(0xFF5C4033),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuidanceCategory {
  final String title;
  final String prompt;

  const _GuidanceCategory({required this.title, required this.prompt});
}

class _GuidanceMessage {
  final String text;
  final bool isUser;

  const _GuidanceMessage({required this.text, required this.isUser});
}
