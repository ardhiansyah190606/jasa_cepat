import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String contactName;
  final String subtitle;
  final bool isCustomerService;

  const ChatScreen({
    super.key,
    this.contactName = 'Budi Setiawan',
    this.subtitle = 'Teknisi AC',
    this.isCustomerService = false,
  });

  @override
  Widget build(BuildContext context) {
    final messages = isCustomerService
        ? [
            _ChatMessage(text: 'Halo, selamat datang di CS JasaCepat. Ada yang bisa kami bantu?', isMe: false, time: 'Sekarang'),
          ]
        : [
            _ChatMessage(text: 'Halo pak, saya sudah di jalan ya menuju rumah.', isMe: false, time: '14:25'),
            _ChatMessage(text: 'Siap, saya menunggu di rumah.', isMe: true, time: '14:26'),
            _ChatMessage(text: 'Terima kasih, teknisi akan tiba sekitar 10 menit lagi.', isMe: false, time: '14:27'),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chat', style: TextStyle(fontSize: 18)),
            Text('$contactName - $subtitle', style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return Align(
                  alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: message.isMe ? Colors.blue : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: TextStyle(color: message.isMe ? Colors.white : Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message.time,
                          style: TextStyle(
                            fontSize: 11,
                            color: message.isMe ? Colors.white70 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Ketik pesan...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.send, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isMe;
  final String time;

  const _ChatMessage({required this.text, required this.isMe, required this.time});
}
