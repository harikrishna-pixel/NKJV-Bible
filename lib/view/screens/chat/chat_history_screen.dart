import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:biblebookapp/view/constants/colors.dart';
import 'package:biblebookapp/view/constants/theme_provider.dart';
import 'package:biblebookapp/view/screens/chat/chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:biblebookapp/view/constants/constant.dart';
import 'package:biblebookapp/view/constants/images.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<ChatHistoryItem> _historyItems = [];
  bool _isSelectionMode = false;
  Set<String> _selectedItems = <String>{};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('chat_history_')).toList();
    
    final List<ChatHistoryItem> items = [];
    for (final key in keys) {
      final conversationId = key.replaceFirst('chat_history_', '');
      final historyJson = prefs.getString(key);
      
      if (historyJson != null) {
        final List<dynamic> history = jsonDecode(historyJson);
        if (history.isNotEmpty) {
          DateTime date;
          String preview;
          
          // Try to get metadata first
          final metaKey = 'chat_meta_$conversationId';
          final metaJson = prefs.getString(metaKey);
          
          if (metaJson != null) {
            try {
              final meta = jsonDecode(metaJson);
              date = DateTime.parse(meta['date'] as String);
              preview = meta['preview'] as String;
            } catch (e) {
              // Fallback to parsing from conversation ID or using first message
              date = DateTime.now();
              preview = history.first['text'] as String;
              if (preview.length > 50) {
                preview = '${preview.substring(0, 50)}...';
              }
            }
          } else {
            // Fallback: try to parse date from old format or use current date
            try {
              date = DateFormat('yyyy-MM-dd').parse(conversationId);
            } catch (e) {
              // If it's a conversation ID (conv_xxx), use current date or try to extract from first message timestamp
              if (history.first['timestamp'] != null) {
                try {
                  date = DateTime.parse(history.first['timestamp'] as String);
                } catch (e2) {
                  date = DateTime.now();
                }
              } else {
                date = DateTime.now();
              }
            }
            preview = history.first['text'] as String;
            if (preview.length > 50) {
              preview = '${preview.substring(0, 50)}...';
            }
          }
          
          items.add(ChatHistoryItem(
            date: date,
            preview: preview,
            messageCount: history.length,
            conversationId: conversationId,
          ));
        }
      }
    }
    
    items.sort((a, b) => b.date.compareTo(a.date));
    
    setState(() {
      _historyItems = items;
    });
  }

  Future<void> _deleteHistory(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history_$conversationId');
    await prefs.remove('chat_meta_$conversationId');
    await _loadHistory();
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      Constants.showToast('Deleted successfully', 5000);
    }
  }

  Future<void> _clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('chat_history_')).toList();
    for (final key in keys) {
      await prefs.remove(key);
      final conversationId = key.replaceFirst('chat_history_', '');
      await prefs.remove('chat_meta_$conversationId');
    }
    await _loadHistory();
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      Constants.showToast('Deleted successfully', 5000);
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedItems.clear();
      }
    });
  }

  void _toggleItemSelection(String conversationId) {
    setState(() {
      if (_selectedItems.contains(conversationId)) {
        _selectedItems.remove(conversationId);
      } else {
        _selectedItems.add(conversationId);
      }
      if (_selectedItems.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  Future<void> _deleteSelectedItems() async {
    if (_selectedItems.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    for (final conversationId in _selectedItems) {
      await prefs.remove('chat_history_$conversationId');
      await prefs.remove('chat_meta_$conversationId');
    }
    
    setState(() {
      _selectedItems.clear();
      _isSelectionMode = false;
    });
    
    await _loadHistory();
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      Constants.showToast('Deleted successfully', 5000);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  void _showConversationBottomSheet(String conversationId, double screenWidth, bool isDark) {
    showModalBottomSheet(
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.black.withOpacity(0.5),
      context: context,
      builder: (BuildContext context) {
        return _ConversationBottomSheet(
          conversationId: conversationId,
          screenWidth: screenWidth,
          isDark: isDark,
          onOpenChat: () {
            Navigator.pop(context);
            Get.to(
              () => ChatScreen(historyDateKey: conversationId),
              transition: Transition.cupertinoDialog,
              duration: const Duration(milliseconds: 300),
            )?.then((_) {
              _loadHistory();
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final isVintage = themeProvider.currentCustomTheme == AppCustomTheme.vintage;

    return Scaffold(
      backgroundColor: isVintage
          ? (isDark ? CommanColor.black : themeProvider.backgroundColor)
          : (isDark ? CommanColor.darkPrimaryColor : themeProvider.backgroundColor),
      appBar: AppBar(
        backgroundColor: isVintage
            ? Colors.transparent
            : CommanColor.lightDarkPrimary(context),
        flexibleSpace: isVintage
            ? Container(
                decoration: BoxDecoration(
                  color: isDark ? CommanColor.black : themeProvider.backgroundColor,
                  image: DecorationImage(
                    image: AssetImage(Images.bgImage(context)),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : null,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isVintage 
                ? CommanColor.whiteBlack(context)
                : CommanColor.white,
          ),
          onPressed: () {
            Get.back();

          },
        ),
        title: Text(
          'Chat History',
          style: TextStyle(
            color: isVintage 
                ? CommanColor.whiteBlack(context)
                : CommanColor.white,
            fontSize: screenWidth > 450 ? 22 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: _historyItems.isNotEmpty
            ? [
                if (_isSelectionMode) ...[
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: isVintage 
                          ? CommanColor.whiteBlack(context)
                          : CommanColor.white,
                    ),
                    onPressed: _selectedItems.isEmpty
                        ? null
                        : () {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) {
                                final themeProvider = Provider.of<ThemeProvider>(context);
                                final isDark = themeProvider.themeMode == ThemeMode.dark;
                                final isVintage = themeProvider.currentCustomTheme == AppCustomTheme.vintage;
                                final bgColor = isDark ? const Color(0xFF2A1F12) : Colors.white;
                                final textColor = isDark ? Colors.white : Colors.black;
                                final cancelColor = isDark ? Colors.white70 : Colors.black87;
                                final deleteColor = isDark ? Colors.red[300] : Colors.red;
                                
                                return AlertDialog(
                                  backgroundColor: bgColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  title: Text(
                                    'Delete Selected',
                                    style: TextStyle(
                                      color: textColor,
                                    ),
                                  ),
                                  content: Text(
                                    'Are you sure you want to delete selected conversation(s)?',
                                    style: TextStyle(
                                      color: textColor,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: cancelColor,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Get.back();
                                        _deleteSelectedItems();
                                      },
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: deleteColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: isVintage 
                          ? CommanColor.whiteBlack(context)
                          : CommanColor.white,
                    ),
                    onPressed: _toggleSelectionMode,
                  ),
                ] else ...[
                  IconButton(
                    icon: Icon(
                      Icons.checklist,
                      color: isVintage 
                          ? CommanColor.whiteBlack(context)
                          : CommanColor.white,
                    ),
                    tooltip: 'Select items',
                    onPressed: _toggleSelectionMode,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: isVintage 
                          ? CommanColor.whiteBlack(context)
                          : CommanColor.white,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) {
                          final themeProvider = Provider.of<ThemeProvider>(context);
                          final isDarkDialog = themeProvider.themeMode == ThemeMode.dark;
                          final isVintage = themeProvider.currentCustomTheme == AppCustomTheme.vintage;
                          final bgColor = isDarkDialog ? const Color(0xFF2A1F12) : Colors.white;
                          final textColor = isDarkDialog ? Colors.white : Colors.black;
                          final cancelColor = isDarkDialog ? Colors.white70 : Colors.black87;
                          
                          return AlertDialog(
                            backgroundColor: bgColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            title: Text(
                              'Clear All History',
                              style: TextStyle(
                                color: textColor,
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to delete all chat history?',
                              style: TextStyle(
                                color: textColor,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: cancelColor,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Get.back(result: true);
                                  await _clearAllHistory();
                                },
                                child: Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: isDarkDialog ? Colors.red[300] : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ]
            : null,
      ),
      body: Container(
        decoration: isVintage
            ? BoxDecoration(
                color: isDark ? CommanColor.black : themeProvider.backgroundColor,
                image: DecorationImage(
                  image: AssetImage(Images.bgImage(context)),
                  fit: BoxFit.cover,
                ),
              )
            : null,
        child: _historyItems.isEmpty
            ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 80,
                  color: isDark
                      ? Colors.white.withOpacity(0.6)
                      : CommanColor.lightDarkPrimary(context).withOpacity(0.5),
                ),
                const SizedBox(height: 20),
                Text(
                  'No chat history',
                  style: TextStyle(
                    color: CommanColor.whiteBlack(context).withOpacity(0.7),
                    fontSize: screenWidth > 450 ? 20 : 16,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Start a conversation to see history here',
                  style: TextStyle(
                    color: CommanColor.whiteBlack(context).withOpacity(0.5),
                    fontSize: screenWidth > 450 ? 16 : 14,
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth > 450 ? 60 : 80
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.to(() => const ChatScreen());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CommanColor.lightDarkPrimary(context),
                        foregroundColor: Colors.white,
                        side: isDark
                            ? BorderSide(
                                color:
                                    CommanColor.white.withOpacity(0.8),
                                width: 1.2,
                              )
                            : null,
                        padding: EdgeInsets.symmetric(
                          vertical: screenWidth > 450 ? 14 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                      "Let's Chat",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth > 450 ? 18 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: EdgeInsets.all(screenWidth > 450 ? 16 : 12),
              itemCount: _historyItems.length,
              itemBuilder: (context, index) {
                final item = _historyItems[index];
                return _buildHistoryItem(item, item.conversationId, screenWidth, isDark);
              },
            ),
        ),
      );
  }

  // Function to parse text and highlight verse references
  List<TextSpan> _parseTextWithVerseHighlights(String text, bool isUser, double screenWidth, BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final baseColor = isUser
        ? CommanColor.white
        : CommanColor.whiteBlack(context);
    // Use a brighter, more visible color for dark mode verse highlighting
    final highlightColor = isDark 
        ? const Color(0xFFE5DF0D)  // Yellow/gold color for dark mode - highly visible against dark background
        : CommanColor.lightDarkPrimary(context);  // Primary color for light mode
    
    // Pattern to match verse references like "John 3:16", "Genesis 1:1-3", "1 Corinthians 13:4-7", "John 3:16, 17", etc.
    // Matches: Book name (with optional number prefix) + chapter:verse (with optional verse range or comma-separated verses)
    // More specific pattern to avoid matching standalone numbers
    final versePattern = RegExp(
      r'\b([1-3]?\s?[A-Za-z]{2,}\s+)?(\d{1,3}):(\d{1,3})(?:-(\d{1,3}))?(?:\s*,\s*(\d{1,3}))?',
      caseSensitive: false,
    );
    
    List<TextSpan> spans = [];
    int lastIndex = 0;
    
    for (Match match in versePattern.allMatches(text)) {
      // Add text before the match
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(
            color: baseColor,
            fontSize: screenWidth > 450 ? 16 : 14,
            height: 1.4,
          ),
        ));
      }
      
      // Add highlighted verse reference
      spans.add(TextSpan(
        text: match.group(0),
        style: TextStyle(
          color: highlightColor,
          fontSize: screenWidth > 450 ? 16 : 14,
          height: 1.4,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationThickness: 2,
          decorationStyle: TextDecorationStyle.solid,
        ),
      ));
      
      lastIndex = match.end;
    }
    
    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(
          color: baseColor,
          fontSize: screenWidth > 450 ? 16 : 14,
          height: 1.4,
        ),
      ));
    }
    
    // If no verse references found, return the whole text as a single span
    if (spans.isEmpty) {
      spans.add(TextSpan(
        text: text,
        style: TextStyle(
          color: baseColor,
          fontSize: screenWidth > 450 ? 16 : 14,
          height: 1.4,
        ),
      ));
    }
    
    return spans;
  }

  Widget _buildPreviewWithHighlights(String text, double screenWidth, BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    // Use a brighter, more visible color for highlighting the entire preview text
    final highlightColor = isDark 
        ? const Color(0xFFE5DF0D)  // Yellow/gold color for dark mode
        : CommanColor.lightDarkPrimary(context);  // Primary color for light mode
    
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: highlightColor,
          fontSize: screenWidth > 450 ? 14 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildHistoryItem(
    ChatHistoryItem item,
    String conversationId,
    double screenWidth,
    bool isDark,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Dismissible(
      key: Key(conversationId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete,
          color: CommanColor.white,
        ),
      ),
      onDismissed: (direction) {
        _deleteHistory(conversationId);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: screenWidth > 450 ? 12 : 10),
        decoration: BoxDecoration(
          color: isDark
              ? CommanColor.darkPrimaryColor.withOpacity(0.5)
              : (themeProvider.currentCustomTheme == AppCustomTheme.vintage
                  ? themeProvider.backgroundColor
                  : CommanColor.white),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (_isSelectionMode) {
                _toggleItemSelection(item.conversationId);
              } else {
                _showConversationBottomSheet(item.conversationId, screenWidth, isDark);
              }
            },
            onLongPress: () {
              if (!_isSelectionMode) {
                _toggleSelectionMode();
              }
              _toggleItemSelection(item.conversationId);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(screenWidth > 450 ? 16 : 14),
              child: Row(
                children: [
                  if (_isSelectionMode) ...[
                    Checkbox(
                      value: _selectedItems.contains(item.conversationId),
                      onChanged: (value) {
                        _toggleItemSelection(item.conversationId);
                      },
                      activeColor: CommanColor.lightDarkPrimary(context),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    width: screenWidth > 450 ? 50 : 45,
                    height: screenWidth > 450 ? 50 : 45,
                    decoration: BoxDecoration(
                      color: CommanColor.lightDarkPrimary(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      CupertinoIcons.chat_bubble_2,
                      color: isDark
                        ? Colors.white
                        : CommanColor.lightDarkPrimary(context),
                      size: screenWidth > 450 ? 28 : 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPreviewWithHighlights(
                          item.preview,
                          screenWidth,
                          context,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(item.date),
                          style: TextStyle(
                            color: CommanColor.whiteBlack(context).withOpacity(0.6),
                            fontSize: screenWidth > 450 ? 13 : 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isSelectionMode)
                    Icon(
                      Icons.chevron_right,
                      color: CommanColor.whiteBlack(context).withOpacity(0.5),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChatHistoryItem {
  final DateTime date;
  final String preview;
  final int messageCount;
  final String conversationId;

  ChatHistoryItem({
    required this.date,
    required this.preview,
    required this.messageCount,
    required this.conversationId,
  });
}

class _ConversationBottomSheet extends StatefulWidget {
  final String conversationId;
  final double screenWidth;
  final bool isDark;
  final VoidCallback onOpenChat;

  const _ConversationBottomSheet({
    required this.conversationId,
    required this.screenWidth,
    required this.isDark,
    required this.onOpenChat,
  });

  @override
  State<_ConversationBottomSheet> createState() => _ConversationBottomSheetState();
}

class _ConversationBottomSheetState extends State<_ConversationBottomSheet> {
  List<ChatMessage> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('chat_history_${widget.conversationId}');
    
    if (historyJson != null) {
      final List<dynamic> history = jsonDecode(historyJson);
      setState(() {
        _messages = history.map((item) => ChatMessage.fromJson(item)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isVintage = themeProvider.currentCustomTheme == AppCustomTheme.vintage;
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: widget.isDark
            ? CommanColor.darkPrimaryColor
            : (isVintage
                ? themeProvider.backgroundColor
                : CommanColor.backgrondcolor),
        image: isVintage && !widget.isDark
            ? DecorationImage(
                image: AssetImage(Images.bgImage(context)),
                fit: BoxFit.cover,
              )
            : null,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: CommanColor.lightDarkPrimary(context),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Conversation',
                    style: TextStyle(
                      color: CommanColor.white,
                      fontSize: widget.screenWidth > 450 ? 20 : 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: CommanColor.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        CommanColor.lightDarkPrimary(context),
                      ),
                    ),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages found',
                          style: TextStyle(
                            color: CommanColor.whiteBlack(context).withOpacity(0.7),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(widget.screenWidth > 450 ? 16 : 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(_messages[index], widget.screenWidth);
                        },
                      ),
          ),
          // Footer with Open Chat button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? CommanColor.darkPrimaryColor
                  : (isVintage
                      ? themeProvider.backgroundColor
                      : CommanColor.white),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onOpenChat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isDark
                        ? CommanColor.lightDarkPrimary200(context)
                        : CommanColor.lightDarkPrimary(context),
                    padding: EdgeInsets.symmetric(
                      vertical: widget.screenWidth > 450 ? 16 : 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: widget.isDark ? 4 : 0,
                    shadowColor: widget.isDark 
                        ? CommanColor.lightDarkPrimary200(context).withOpacity(0.3)
                        : null,
                  ),
                  child: Text(
                    'Open in Chat',
                    style: TextStyle(
                      color: CommanColor.white,
                      fontSize: widget.screenWidth > 450 ? 16 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Function to parse text and highlight verse references
  List<TextSpan> _parseTextWithVerseHighlights(String text, bool isUser, double screenWidth, BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final baseColor = isUser
        ? CommanColor.white
        : CommanColor.whiteBlack(context);
    // Use a brighter, more visible color for dark mode verse highlighting
    final highlightColor = isDark 
        ? const Color(0xFFE5DF0D)  // Yellow/gold color for dark mode - highly visible against dark background
        : CommanColor.lightDarkPrimary(context);  // Primary color for light mode
    
    // Pattern to match verse references like "John 3:16", "Genesis 1:1-3", "1 Corinthians 13:4-7", "John 3:16, 17", etc.
    // Matches: Book name (with optional number prefix) + chapter:verse (with optional verse range or comma-separated verses)
    // More specific pattern to avoid matching standalone numbers
    final versePattern = RegExp(
      r'\b([1-3]?\s?[A-Za-z]{2,}\s+)?(\d{1,3}):(\d{1,3})(?:-(\d{1,3}))?(?:\s*,\s*(\d{1,3}))?',
      caseSensitive: false,
    );
    
    List<TextSpan> spans = [];
    int lastIndex = 0;
    
    for (Match match in versePattern.allMatches(text)) {
      // Add text before the match
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(
            color: baseColor,
            fontSize: screenWidth > 450 ? 16 : 14,
            height: 1.4,
          ),
        ));
      }
      
      // Add highlighted verse reference
      spans.add(TextSpan(
        text: match.group(0),
        style: TextStyle(
          color: highlightColor,
          fontSize: screenWidth > 450 ? 16 : 14,
          height: 1.4,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationThickness: 2,
          decorationStyle: TextDecorationStyle.solid,
        ),
      ));
      
      lastIndex = match.end;
    }
    
    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(
          color: baseColor,
          fontSize: screenWidth > 450 ? 16 : 14,
          height: 1.4,
        ),
      ));
    }
    
    // If no verse references found, return the whole text as a single span
    if (spans.isEmpty) {
      spans.add(TextSpan(
        text: text,
        style: TextStyle(
          color: baseColor,
          fontSize: screenWidth > 450 ? 16 : 14,
          height: 1.4,
        ),
      ));
    }
    
    return spans;
  }

  Widget _buildMessageBubble(ChatMessage message, double screenWidth) {
    final isUser = message.isUser;
    final isDark = Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: isUser ? screenWidth * 0.15 : 0,
        right: isUser ? 0 : screenWidth * 0.15,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: screenWidth > 450 ? 18 : 16,
              backgroundColor: CommanColor.lightDarkPrimary(context),
              child: Image.asset("assets/Mask group.png"),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                _showMessageOptions(context, message, screenWidth, isDark);
              },
              child: Container(
                padding: EdgeInsets.all(screenWidth > 450 ? 16 : 12),
                decoration: BoxDecoration(
                  color: isUser
                      ? CommanColor.lightDarkPrimary(context)
                      : (isDark
                          ? CommanColor.darkPrimaryColor.withOpacity(0.3)
                          : (Provider.of<ThemeProvider>(context, listen: false).currentCustomTheme == AppCustomTheme.vintage
                              ? Provider.of<ThemeProvider>(context, listen: false).backgroundColor
                              : CommanColor.backgrondcolor)),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: _parseTextWithVerseHighlights(
                          message.text,
                          isUser,
                          screenWidth,
                          context,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm').format(message.timestamp),
                      style: TextStyle(
                        color: isUser
                            ? CommanColor.white.withOpacity(0.7)
                            : CommanColor.whiteBlack(context).withOpacity(0.5),
                        fontSize: screenWidth > 450 ? 12 : 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: screenWidth > 450 ? 18 : 16,
              backgroundColor: CommanColor.lightDarkPrimary(context).withOpacity(0.3),
              child: Icon(
                Icons.person,
                size: screenWidth > 450 ? 20 : 18,
                color: isDark
                    ? Colors.white
                    : CommanColor.lightDarkPrimary(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showMessageOptions(BuildContext context, ChatMessage message, double screenWidth, bool isDark) {
    // Get theme provider values with listen: false to avoid provider errors
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final primaryColor = themeProvider.themeMode == ThemeMode.dark
        ? CommanColor.darkPrimaryColor
        : CommanColor.lightModePrimary;
    final textColor = themeProvider.themeMode == ThemeMode.dark
        ? CommanColor.white
        : CommanColor.black;
    
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(overlay.size.width / 2 - 100, overlay.size.height / 2, 200, 0),
        Offset.zero & overlay.size,
      ),
      color: isDark ? CommanColor.darkPrimaryColor : CommanColor.white,
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: primaryColor,
                    width: 1.4,
                  ),
                ),
                child: Image.asset(
                  "assets/Bookmark icons/Frame 3630.png",
                  height: screenWidth > 450 ? 20 : 18,
                  width: screenWidth > 450 ? 20 : 18,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Copy',
                style: TextStyle(
                  color: textColor,
                  fontSize: screenWidth > 450 ? 16 : 14,
                ),
              ),
            ],
          ),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: message.text));
            Constants.showToast('Message copied to clipboard', 5000);
          },
        ),
        if (!message.isUser) // Only show Share for reply messages
          PopupMenuItem(
            child: Row(
              children: [
                Icon(
                  Icons.share,
                  size: screenWidth > 450 ? 20 : 18,
                  color: primaryColor,
                ),
                const SizedBox(width: 12),
                Text(
                  'Share',
                  style: TextStyle(
                    color: textColor,
                    fontSize: screenWidth > 450 ? 16 : 14,
                  ),
                ),
              ],
            ),
            onTap: () async {
              // Get screen size for sharePositionOrigin (required on iOS)
              final screenSize = MediaQuery.of(context).size;
              final sharePositionOrigin = Rect.fromLTWH(
                screenSize.width / 2 - 50,
                screenSize.height / 2 - 50,
                100,
                100,
              );
              await Share.share(
                message.text,
                sharePositionOrigin: sharePositionOrigin,
              );
            },
          ),
      ],
    );
  }
}

