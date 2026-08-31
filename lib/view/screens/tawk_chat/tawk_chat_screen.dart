import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tawkto/flutter_tawk.dart';
import 'package:get/get.dart';

class TawkChatScreen extends StatelessWidget {
  const TawkChatScreen({super.key});

  static String get _directChatLink =>
      (dotenv.env['TAWK_DIRECT_CHAT_LINK'] ?? '').trim();

  @override
  Widget build(BuildContext context) {
    final link = _directChatLink;

    return Scaffold(
        backgroundColor: Color(0XFF0803A8),
        appBar: AppBar(
          backgroundColor: Color(0XFF0803A8),
          title: const Text(
            'Chat Us',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: link.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                              onDoubleTap: () {
                                Get.back();
                              },
                              child: Icon(
                                Icons.arrow_back_ios,
                                color: Colors.black12,
                              )),
                          Text(
                            'Chat is not configured.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: CommanColor.whiteBlack(context),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Please add `TAWK_DIRECT_CHAT_LINK` in your `.env` file.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: CommanColor.whiteBlack(context)
                                  .withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Constants.showToast(
                                  'Missing TAWK_DIRECT_CHAT_LINK in .env');
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Tawk(
                  directChatLink: link,
                  visitor: TawkVisitor(
                    name: 'Bible Book App User',
                    email: '', // Can be populated with user email if available
                  ),
                  onLoad: () {
                    debugPrint('📞 TAWK: Chat loaded - App: Bible Book App');
                  },
                  onLinkTap: (String url) {
                    debugPrint('📞 TAWK: Link tapped: $url');
                  },
                  placeholder: const Center(child: CircularProgressIndicator()),
                ),
        ));
  }
}
