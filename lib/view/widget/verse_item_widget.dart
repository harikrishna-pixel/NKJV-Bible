import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/parser.dart';

import 'package:biblebookapp/Model/verseBookContentModel.dart';
import 'package:biblebookapp/controller/dashboard_controller.dart';
import 'package:biblebookapp/controller/dpProvider.dart';
import 'package:biblebookapp/view/screens/dashboard/constants.dart';
import 'package:html_unescape/html_unescape.dart';

import '../constants/colors.dart';

class VerseItemWidget extends StatefulWidget {
  const VerseItemWidget({
    super.key,
    required this.controller,
    required this.data,
    required this.selectedVerseForRead,
    required this.index,
    required this.currentindex,
    this.selectedColor,
  });

  final int index;
  final int currentindex;
  final DashBoardController controller;
  final VerseBookContentModel data;
  final String selectedVerseForRead;
  final String? selectedColor;

  @override
  State<VerseItemWidget> createState() => _VerseItemWidgetState();
}

class _VerseItemWidgetState extends State<VerseItemWidget> {
  bool showTempHighlight = false;

  @override
  void initState() {
    super.initState();
    _checkTempHighlight();
  }

  void _checkTempHighlight() {
    final parsedText =
        parse(widget.data.content).body?.text ?? widget.data.content;
    if (widget.controller.readHighlight.value &&
        parsedText == widget.selectedVerseForRead) {
      if (mounted) {
        setState(() {
          showTempHighlight = true;
        });
      }

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            showTempHighlight = false;
          });
        }
      });
    }
  }

  Color _parseColor(String? colorStr, {Color fallback = Colors.transparent}) {
    // debugPrint("Color parse : $colorStr");
    try {
      // if (colorStr == null || colorStr.isEmpty) return fallback;
      return Color(int.parse(colorStr.toString()));
    } catch (e) {
      // debugPrint("color error is $e");
      return fallback;
    }
  }

  // Color _parseColor(String? colorStr, {Color fallback = Colors.transparent}) {
  //   debugPrint("Color parse : $colorStr");

  //   try {
  //     if (colorStr == null || colorStr.isEmpty) return fallback;

  //     String value = colorStr.trim();

  //     // Remove leading '#' if present and ensure proper format
  //     if (value.startsWith('#')) {
  //       value = value.substring(1);
  //     }

  //     // Add full opacity if only 6-digit hex is provided
  //     if (value.length == 6) {
  //       value = 'FF$value'; // FF for 100% opacity
  //     }

  //     // Parse as radix-16 (hexadecimal)
  //     return Color(int.parse(value, radix: 16));
  //   } catch (e) {
  //     debugPrint("Color parse error: $e");
  //     return fallback;
  //   }
  // }

  TextStyle _getTextStyle(
      BuildContext context,
      double screenWidth,
      bool isTempSelected,
      bool isHighlighted,
      bool isUnderlined,
      ) {
    final baseStyle = TextStyle(
      letterSpacing: BibleInfo.letterSpacing,
      fontSize: screenWidth > 450
          ? BibleInfo.fontSizeScale * widget.controller.fontSize.value
          : BibleInfo.fontSizeScale * widget.controller.fontSize.value,
      fontFamily: widget.controller.selectedFontFamily.value,
      decoration: isUnderlined ? TextDecoration.underline : TextDecoration.none,
    );

    if (isTempSelected) {
      return baseStyle.copyWith(backgroundColor: const Color(0xFFf2b272));
    }

    if (isHighlighted) {
      return baseStyle.copyWith(color: CommanColor.black);
    }

    return baseStyle.copyWith(
      color: CommanColor.whiteBlack(context),
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final parsedText =
        parse(widget.data.content).body?.text ?? widget.data.content;
    final verseLabel =
        displayVerseNumber(widget.data, listIndex: widget.index);
    final isHighlighted = widget.data.isHighlighted != "no";
    final isUnderlined = widget.data.isUnderlined == "yes";
    final isBookmarked = widget.data.isBookmarked == "yes";
    final isNoted = widget.data.isNoted != "no";

    //  final normalized = normalizeHtml(widget.data.content);

    return FutureBuilder<String?>(
      future: DBHelper().getColorByContent(widget.data.content),
      builder: (context, snapshot) {
        final highlightColor =
            widget.data.isHighlighted ?? widget.selectedColor;

        //   debugPrint("Color parse 1 : ${widget.data.content} $highlightColor");

        final bgColor = isHighlighted
            ? _parseColor(highlightColor, fallback: Colors.transparent)
            : Colors.transparent;
        // debugPrint("Color parse 2 : $highlightColor");
        return Container(
          color: bgColor,
          // decoration: BoxDecoration(color: bgColor),
          child: RichText(
            text: TextSpan(
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.top,
                  child: HtmlWidget(
                    "$verseLabel. $parsedText",
                    // "And the earth was without form, and void; and darkness <em>was</em> upon the face of the deep. And the Spirit of God moved upon the face of the waters.",
                    textStyle: _getTextStyle(
                      context,
                      screenWidth,
                      showTempHighlight,
                      isHighlighted,
                      isUnderlined,
                    ),
                  ),
                ),
                // TextSpan(
                //   text: // "And the earth was without form, and void; and darkness <em>was</em> upon the face of the deep. And the Spirit of God moved upon the face of the waters.",
                //"${widget.index + 1}. $parsedText",

                //   style: _getTextStyle(
                //     context,
                //     screenWidth,
                //     showTempHighlight,
                //     isHighlighted,
                //     isUnderlined,
                //   ),
                // ),
                if (isBookmarked)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 3.0),
                      child: Icon(
                        Icons.bookmark,
                        color: CommanColor.whiteLightModePrimary(context),
                        size: screenWidth > 450
                            ? widget.controller.fontSize.value * 1.6
                            : widget.controller.fontSize.value * 1.2,
                      ),
                    ),
                  ),
                if (isNoted)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 5.0),
                      child: Image.asset(
                        CommanColor.isDarkTheme(context)
                            ? "assets/light_modes/stickynote.png"
                            : "assets/Bookmark icons/stickynote-1.png",
                        width: screenWidth > 450
                            ? widget.controller.fontSize.value * 1.6
                            : widget.controller.fontSize.value * 1.2,
                        height: screenWidth > 450
                            ? widget.controller.fontSize.value * 1.6
                            : widget.controller.fontSize.value * 1.2,
                        color: null,
                        fit: BoxFit.contain,
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

  String normalizeHtml(String htmlContent) {
    final unescape = HtmlUnescape();
    final document = html_parser.parse(htmlContent);
    final normalized =
    unescape.convert(document.body?.text ?? htmlContent).trim();
    return normalized.replaceAll("'", '').replaceAll('"', '');
    // return unescape.convert(document.body?.text ?? htmlContent).trim();
  }
}

// class VerseItemWidget extends StatefulWidget {
//   const VerseItemWidget(
//       {super.key,
//       required this.controller,
//       required this.data,
//       required this.selectedVerseForRead,
//       required this.index,
//       this.selectedColor});
//   final int index;
//   final DashBoardController controller;
//   final VerseBookContentModel data;
//   final String selectedVerseForRead;
//   final String? selectedColor;

//   @override
//   State<VerseItemWidget> createState() => _VerseItemWidgetState();
// }

// class _VerseItemWidgetState extends State<VerseItemWidget> {
//   String? highlightContentcolor;

//   @override
//   void initState() {
//     gethighligthcolor();
//     super.initState();
//   }

//   gethighligthcolor() async {
//     final data = await DBHelper().getColorByContent(widget.data.content);
//     if (mounted) {
//       setState(() {
//         highlightContentcolor = data;
//       });
//     }
//   }

//   @override
//   void didUpdateWidget(covariant VerseItemWidget oldWidget) {
//     gethighligthcolor();
//     super.didUpdateWidget(oldWidget);
//   }

//   @override
//   Widget build(BuildContext context) {
//     double screenWidth = MediaQuery.of(context).size.width;
//     debugPrint("sz current width - $screenWidth ");

// // Define your common text style first
//     final baseStyle = TextStyle(
//       fontSize: screenWidth > 450
//           ? BibleInfo.fontSizeScale * 30
//           : BibleInfo.fontSizeScale * widget.controller.fontSize.value,
//       fontFamily: widget.controller.selectedFontFamily.value,
//       color: widget.controller.readHighlight.value == true &&
//               '${parse(widget.data.content).body?.text ?? widget.data.content}' ==
//                   widget.selectedVerseForRead
//           ? Colors.black
//           : widget.data.isHighlighted == "no"
//               ? CommanColor.whiteBlack(context)
//               : CommanColor.black,
//       backgroundColor: widget.controller.readHighlight.value == true &&
//               '${parse(widget.data.content).body?.text ?? widget.data.content}' ==
//                   widget.selectedVerseForRead
//           ? Color(0xFFf2b272)
//           : Colors.transparent,
//       decoration: widget.data.isUnderlined == "yes"
//           ? TextDecoration.underline
//           : TextDecoration.none,
//       letterSpacing: BibleInfo.letterSpacing,
//     );

// // Parse HTML and separate parts
//     final rawHtml = widget.data.content;
//     final document = html_parser.parse(rawHtml);
//     final spans = <TextSpan>[];

// // Recursively walk through the HTML nodes and convert to TextSpans
//     void extractTextSpans(dom.Node node) {
//       if (node is dom.Text) {
//         spans.add(TextSpan(
//           text: node.text,
//           style: baseStyle,
//         ));
//       } else if (node is dom.Element) {
//         final isItalic = node.localName == 'i';
//         for (var child in node.nodes) {
//           spans.add(TextSpan(
//             text: child.text,
//             style: baseStyle.copyWith(
//               fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
//             ),
//           ));
//         }
//       }
//     }

// // Build spans
//     final body = document.body;
//     if (body != null) {
//       for (var node in body.nodes) {
//         extractTextSpans(node);
//       }
//     }

//     return Obx(() {
//       return
//           //Container(
//           //   decoration: BoxDecoration(
//           //     color: widget.data.isHighlighted == "no"
//           //         ? null
//           //         : highlightContentcolor != null
//           //             ? Color(int.tryParse(highlightContentcolor ?? '0x00000000') ??
//           //                 0x00000000)
//           //             : Color(int.tryParse(widget.selectedColor.toString()) ??
//           //                 0x00000000),
//           //   ),
//           //   child: Row(
//           //     crossAxisAlignment: CrossAxisAlignment.start,
//           //     children: [
//           //       Expanded(
//           //         child: HtmlWidget(
//           //           '''
//           //     <span style="
//           //       font-family: ${widget.controller.selectedFontFamily.value};
//           //       font-size: ${screenWidth > 450 ? BibleInfo.fontSizeScale * 30 : BibleInfo.fontSizeScale * widget.controller.fontSize.value}px;

//           //     ">
//           //       ${widget.index + 1}. ${widget.data.content}
//           //     </span>
//           //     ''',
//           //           textStyle: widget.controller.readHighlight.value == true &&
//           //                   '${parse(widget.data.content).body?.text ?? widget.data.content}' ==
//           //                       widget.selectedVerseForRead
//           //               ? TextStyle(
//           //                   letterSpacing: BibleInfo.letterSpacing,
//           //                   fontSize: screenWidth > 450
//           //                       ? BibleInfo.fontSizeScale * 30
//           //                       : BibleInfo.fontSizeScale *
//           //                           widget.controller.fontSize.value,
//           //                   fontFamily: widget.controller.selectedFontFamily.value,
//           //                   backgroundColor:
//           //                       Provider.of<ThemeProvider>(context).themeMode ==
//           //                               ThemeMode.dark
//           //                           ? Color(int.parse("0xFFf2b272"))
//           //                           : Color(int.parse("0xFFf2b272")),
//           //                   decoration: widget.data.isUnderlined == "yes"
//           //                       ? TextDecoration.underline
//           //                       : TextDecoration.none,
//           //                 )
//           //               : widget.data.isHighlighted == "no"
//           //                   ? TextStyle(
//           //                       letterSpacing: BibleInfo.letterSpacing,
//           //                       fontSize: screenWidth > 450
//           //                           ? BibleInfo.fontSizeScale * 30
//           //                           : BibleInfo.fontSizeScale *
//           //                               widget.controller.fontSize.value,
//           //                       color: CommanColor.whiteBlack(context),
//           //                       fontFamily:
//           //                           widget.controller.selectedFontFamily.value,
//           //                       backgroundColor: Colors.transparent,
//           //                       decoration: widget.data.isUnderlined == "yes"
//           //                           ? TextDecoration.underline
//           //                           : TextDecoration.none,
//           //                     )
//           //                   : TextStyle(
//           //                       letterSpacing: BibleInfo.letterSpacing,
//           //                       fontSize: screenWidth > 450
//           //                           ? BibleInfo.fontSizeScale * 30
//           //                           : BibleInfo.fontSizeScale *
//           //                               widget.controller.fontSize.value,
//           //                       fontFamily:
//           //                           widget.controller.selectedFontFamily.value,
//           //                       color: CommanColor.black,
//           //                       // backgroundColor:
//           //                       //     // highlightContentcolor != null
//           //                       //     //     ? Color(int.tryParse(highlightContentcolor ??
//           //                       //     //             '0x00000000') ??
//           //                       //     //         0x00000000)
//           //                       //     //     :
//           //                       //     Color(int.tryParse(
//           //                       //             widget.selectedColor.toString()) ??
//           //                       //         0x00000000),
//           //                       decoration: widget.data.isUnderlined == "yes"
//           //                           ? TextDecoration.underline
//           //                           : TextDecoration.none,
//           //                     ),
//           //         ),
//           //       ),

//           //       // Bookmark Icon
//           //       if (widget.data.isBookmarked == "yes")
//           //         Padding(
//           //           padding: const EdgeInsets.only(left: 3.0),
//           //           child: Icon(
//           //             Icons.bookmark,
//           //             color: CommanColor.whiteLightModePrimary(context),
//           //             size: screenWidth > 450
//           //                 ? widget.controller.fontSize.value * 1.6
//           //                 : widget.controller.fontSize.value * 1.2,
//           //           ),
//           //         ),

//           //       // Note Icon
//           //       if (widget.data.isNoted != "no")
//           //         Padding(
//           //           padding: const EdgeInsets.only(left: 5.0),
//           //           child: Icon(
//           //             Icons.sticky_note_2_sharp,
//           //             color: CommanColor.whiteLightModePrimary(context),
//           //             size: screenWidth > 450
//           //                 ? widget.controller.fontSize.value * 1.6
//           //                 : widget.controller.fontSize.value * 1.2,
//           //           ),
//           //         ),
//           //     ],
//           //   ),
//           // );

//           Container(
//         decoration: BoxDecoration(
//           color: widget.data.isHighlighted == "no"
//               ? null
//               : highlightContentcolor != null
//                   ? Color(int.tryParse(highlightContentcolor ?? '0x00000000') ??
//                       0x00000000)
//                   : Color(int.tryParse(widget.selectedColor.toString()) ??
//                       0x00000000),
//         ),
//         child: RichText(
//           strutStyle: widget.data.isHighlighted == "no"
//               ? null
//               : StrutStyle(height: widget.controller.fontSize.value / 10),
//           text: TextSpan(
//             children: [
//               // // Main text content with underline handling
//               TextSpan(
//                 text:
//                     "${widget.index + 1}. ${parse(widget.data.content).body?.text ?? widget.data.content}",
//                 style: widget.controller.readHighlight.value == true &&
//                         '${parse(widget.data.content).body?.text ?? widget.data.content}' ==
//                             widget.selectedVerseForRead
//                     ? TextStyle(
//                         letterSpacing: BibleInfo.letterSpacing,
//                         fontSize: screenWidth > 450
//                             ? BibleInfo.fontSizeScale * 30
//                             : BibleInfo.fontSizeScale *
//                                 widget.controller.fontSize.value,
//                         fontFamily: widget.controller.selectedFontFamily.value,
//                         backgroundColor:
//                             Provider.of<ThemeProvider>(context).themeMode ==
//                                     ThemeMode.dark
//                                 ? Color(int.parse("0xFFf2b272"))
//                                 : Color(int.parse("0xFFf2b272")),
//                         decoration: widget.data.isUnderlined == "yes"
//                             ? TextDecoration.underline
//                             : TextDecoration.none,
//                       )
//                     : widget.data.isHighlighted == "no"
//                         ? TextStyle(
//                             letterSpacing: BibleInfo.letterSpacing,
//                             fontSize: screenWidth > 450
//                                 ? BibleInfo.fontSizeScale * 30
//                                 : BibleInfo.fontSizeScale *
//                                     widget.controller.fontSize.value,
//                             color: CommanColor.whiteBlack(context),
//                             fontFamily:
//                                 widget.controller.selectedFontFamily.value,
//                             backgroundColor: Colors.transparent,
//                             decoration: widget.data.isUnderlined == "yes"
//                                 ? TextDecoration.underline
//                                 : TextDecoration.none,
//                           )
//                         : TextStyle(
//                             letterSpacing: BibleInfo.letterSpacing,
//                             fontSize: screenWidth > 450
//                                 ? BibleInfo.fontSizeScale * 30
//                                 : BibleInfo.fontSizeScale *
//                                     widget.controller.fontSize.value,
//                             fontFamily:
//                                 widget.controller.selectedFontFamily.value,
//                             color: CommanColor.black,
//                             // backgroundColor:
//                             //     // highlightContentcolor != null
//                             //     //     ? Color(int.tryParse(highlightContentcolor ??
//                             //     //             '0x00000000') ??
//                             //     //         0x00000000)
//                             //     //     :
//                             //     Color(int.tryParse(
//                             //             widget.selectedColor.toString()) ??
//                             //         0x00000000),
//                             decoration: widget.data.isUnderlined == "yes"
//                                 ? TextDecoration.underline
//                                 : TextDecoration.none,
//                           ),
//               ),

//               // Bookmark Icon if applicable
//               if (widget.data.isBookmarked == "yes")
//                 WidgetSpan(
//                   alignment: PlaceholderAlignment.middle,
//                   child: Padding(
//                     padding: const EdgeInsets.only(left: 3.0),
//                     child: Icon(
//                       Icons.bookmark,
//                       color: CommanColor.whiteLightModePrimary(context),
//                       size: screenWidth > 450
//                           ? widget.controller.fontSize.value * 1.6
//                           : widget.controller.fontSize.value *
//                               1.2, // Proportional size
//                     ),
//                   ),
//                 ),

//               // Note Icon if applicable
//               if (widget.data.isNoted != "no")
//                 WidgetSpan(
//                   alignment: PlaceholderAlignment.middle,
//                   child: Padding(
//                     padding: const EdgeInsets.only(left: 5.0),
//                     child: Icon(
//                       Icons.sticky_note_2_sharp,
//                       color: CommanColor.whiteLightModePrimary(context),
//                       size: screenWidth > 450
//                           ? widget.controller.fontSize.value * 1.6
//                           : widget.controller.fontSize.value *
//                               1.2, // Proportional size
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       );
//     });
//   }
// }