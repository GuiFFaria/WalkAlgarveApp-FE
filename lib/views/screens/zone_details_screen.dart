import 'package:flutter/material.dart';

class ZoneDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> zone;

  const ZoneDetailsScreen({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    final imageUrl = zone["thumbnail_url"] ?? "";
    final title = zone["name"] ?? "Sem título";
    final description = zone["description"] ?? "Sem descrição disponível.";
    final bool userHasZone = zone["user_have"] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🖼️ Imagem topo
          SizedBox(
            width: double.infinity,
            height: 180,
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Image.asset("assets/default.jpg", fit: BoxFit.cover),
                  )
                : Image.asset("assets/default.jpg", fit: BoxFit.cover),
          ),

          // 📄 Conteúdo scrollável
          Expanded(
            child: SingleChildScrollView(
              // Mantém padding do conteúdo
              child: Container(
                width: double.infinity, // ✅ garante que o content ocupe toda a largura
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // força alinhamento à esquerda
                  children: [
                    Text(
                      "About this zone",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      textAlign: TextAlign.left,
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                    const SizedBox(height: 80), // espaço para botão
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // 📌 Botão no fundo
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: userHasZone ? Colors.green : Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                if (userHasZone) {
                  // Navega para trilhos da zona
                  // Navigator.push(context, MaterialPageRoute(
                  //   builder: (_) => TrailsListScreen(zoneId: zone["id"]),
                  // ));
                } else {
                  // Lógica de compra (p.ex. abrir checkout)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Redirecting to purchase..."),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text(
                userHasZone ? "View trails" : "Unlock zone",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
