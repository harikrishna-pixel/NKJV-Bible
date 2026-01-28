import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tawkto/flutter_tawk.dart';

class TawkChatScreen extends StatelessWidget {
  const TawkChatScreen({super.key});

  static String get _directChatLink =>
      (dotenv.env['TAWK_DIRECT_CHAT_LINK'] ?? '').trim();

  @override
  Widget build(BuildContext context) {
    final link = _directChatLink;

    return Scaffold(
      backgroundColor: CommanColor.Blackwhite(context),
      appBar: AppBar(
        backgroundColor: CommanColor.lightDarkPrimary(context),
        title: const Text(
          'Chat Us',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: link.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                        color: CommanColor.whiteBlack(context).withOpacity(0.8),
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
            )
          : Tawk(
              directChatLink: link,
              placeholder: const Center(child: CircularProgressIndicator()),
            ),
    );
  }
}
