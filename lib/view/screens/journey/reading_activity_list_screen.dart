import 'package:biblebookapp/services/reading_activity_service.dart';
import 'package:biblebookapp/view/screens/journey/journey_parchment.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReadingActivityListScreen extends StatelessWidget {
  const ReadingActivityListScreen({
    super.key,
    required this.items,
    required this.onOpen,
    this.whenLabelFor,
  });

  final List<ReadingActivity> items;
  final Future<void> Function(ReadingActivity item) onOpen;
  final String Function(ReadingActivity item)? whenLabelFor;

  @override
  Widget build(BuildContext context) {
    final ordered = List<ReadingActivity>.from(items)
      ..sort(ReadingActivity.compareNewestCompletedFirst);
    return Container(
      decoration: journeyParchmentDecoration(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF3D2E24)),
            onPressed: () => Get.back(),
          ),
          title: const Text(
            'Recent Activity',
            style: TextStyle(
              color: Color(0xFF3D2E24),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: items.isEmpty
            ? const Center(
                child: Text(
                  'No reading activity yet.',
                  style: TextStyle(color: Color(0xFF8A7A6C)),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: ordered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = ordered[index];
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => onOpen(item),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: Color(0xFF3D2E24),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    whenLabelFor?.call(item) ?? item.whenLabel,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF8A7A6C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Color(0xFF8A7A6C)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
