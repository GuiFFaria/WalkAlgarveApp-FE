import 'package:flutter/material.dart';

class PoiInfoPopup extends StatefulWidget {
  final dynamic poi;
  final VoidCallback onClose;

  const PoiInfoPopup({
    super.key,
    required this.poi,
    required this.onClose,
  });

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
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Material(
        elevation: 20,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          height: 360,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              /// Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.poi['properties']?['name'] ?? "Ponto de Interesse",
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

              /// Paginator
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _pageIndex = i),
                  children: [
                    _infoPage("Fauna", widget.poi['properties']?['fauna']),
                    _infoPage("Flora", widget.poi['properties']?['flora']),
                    _infoPage(
                        "Geologia", widget.poi['properties']?['geology']),
                    _messagesPage(),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              /// Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _pageIndex == i ? 10 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _pageIndex == i
                          ? Colors.blue
                          : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
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

  Widget _infoPage(String title, dynamic content) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            content?.toString() ?? "Sem informação disponível.",
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _messagesPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Mensagens dos utilizadores",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: ListView(
            children: _messages
                .map((m) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text("• $m"),
                    ))
                .toList(),
          ),
        ),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration:
                    const InputDecoration(hintText: "Deixa uma mensagem"),
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
            )
          ],
        )
      ],
    );
  }
}
