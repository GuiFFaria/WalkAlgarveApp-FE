import 'package:flutter/material.dart';
import 'package:walk_algarve_app/l10n/app_localizations.dart';

class PoiInfoPopup extends StatefulWidget {
  final dynamic poi;
  final VoidCallback onClose;

  const PoiInfoPopup({super.key, required this.poi, required this.onClose});

  @override
  State<PoiInfoPopup> createState() => _PoiInfoPopupState();
}

class _PoiInfoPopupState extends State<PoiInfoPopup> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  final TextEditingController _messageController = TextEditingController();
  final List<String> _messages = [];

  @override
  void dispose() {
    _pageController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context)!;

    return Material(
      elevation: 20,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        height: 600,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.poi['properties']?['name'] ??
                        translations.poi_default_name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),

            const SizedBox(height: 8),

            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _pageIndex = i),
                children: [
                  _infoPage(
                    translations.fauna,
                    widget.poi['properties']?['fauna'],
                    translations,
                  ),
                  _infoPage(
                    translations.flora,
                    widget.poi['properties']?['flora'],
                    translations,
                  ),
                  _infoPage(
                    translations.geology,
                    widget.poi['properties']?['geology'],
                    translations,
                  ),
                  _messagesPage(translations),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _pageIndex == i ? 10 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _pageIndex == i ? Colors.blue : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoPage(
    String title,
    dynamic content,
    AppLocalizations translations,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            content?.toString() ?? translations.no_info,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _messagesPage(AppLocalizations translations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translations.user_messages,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: _messages
                .map(
                  (m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text("• $m"),
                  ),
                )
                .toList(),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: translations.leave_message,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                if (_messageController.text.trim().isEmpty) return;
                setState(() {
                  _messages.add(_messageController.text.trim());
                  _messageController.clear();
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}
