import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_page.dart';
import '../widgets/app_app_bar.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _messageController = TextEditingController();

  final List<Map<String, dynamic>> messages = [
    {
      "text":
          "Saha Sağlık Asistanı. Mevcut ölçüm aralıkları hakkında bilgi verebilirim; teşhis koyamam.",
      "isBot": true,
    },
  ];

  final List<String> quickQuestions = [
    "Nabız aralığı nedir?",
    "SpO₂ nasıl okunur?",
    "Cilt sıcaklığı eşiği nedir?",
  ];

  String _replyFor(String message) {
    final q = message.toLowerCase();
    if (q.contains('nabız') || q.contains('bpm') || q.contains('kalp')) {
      return 'Nabız değeriniz mevcut ölçümlerde 60–100 BPM aralığında görünüyorsa normal kabul edilir. 50 altı veya 120 üstü anomali olarak izlenir.';
    }
    if (q.contains('spo') || q.contains('oksijen')) {
      return 'SpO₂ için normal aralık %95–100 olarak izlenir. %90–94 dikkat, %90 altı kritik kabul edilir. Teşhis koyamam.';
    }
    if (q.contains('sıcak') || q.contains('ısı') || q.contains('temp')) {
      return 'Cilt sıcaklığı için normal aralık 33–37 °C olarak izlenir. 38.5 °C üzeri kritik ısı yüklenmesi olarak değerlendirilir.';
    }
    if (q.contains('gsr') || q.contains('stres')) {
      return 'GSR / stres göstergesi dinlenimde düşük görünür. Yüksek ve süren değerler stres uyarısı olarak izlenir; teşhis niteliği taşımaz.';
    }
    return 'Ölçümlerinizi ana sayfadaki fizyolojik kartlardan izleyebilirsiniz. Teşhis koyamam. Acil durumda ACİL butonunu kullanın.';
  }

  void _sendMessage([String? text]) {
    final message = text ?? _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      messages.add({"text": message, "isBot": false});
      _messageController.clear();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        messages.add({"text": _replyFor(message), "isBot": true});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text("Saha Sağlık Asistanı"),
      ),
      child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return Align(
                      alignment:
                          msg['isBot']
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                      child: ChatBubble(
                        message: msg['text'],
                        isBot: msg['isBot'],
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  children:
                      quickQuestions.map((question) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            title: Text(
                              question,
                              style: const TextStyle(fontSize: 16),
                            ),
                            onTap: () => _sendMessage(question),
                            trailing: const Icon(
                              Icons.send,
                              color: AppColors.muted,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),

              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: "Ölçüm aralığı sorun",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: AppColors.forest,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () => _sendMessage(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isBot;

  const ChatBubble({super.key, required this.message, required this.isBot});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: isBot ? AppColors.paper : AppColors.forest,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isBot ? 0 : 16),
          bottomRight: Radius.circular(isBot ? 16 : 0),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isBot ? AppColors.ink : Colors.white,
          fontSize: 18,
        ),
      ),
    );
  }
}
