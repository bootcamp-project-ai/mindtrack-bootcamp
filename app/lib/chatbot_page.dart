import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];

  final String apiKey = "AIzaSyA3XIa-TVF3_otsJBCt9-wRSsqIwRerJEc";

  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": userMessage});
      _controller.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    final uri = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey");

    final body = jsonEncode({
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": userMessage}
          ]
        }
      ]
    });

    try {
      final response = await http
          .post(uri,
              headers: {"Content-Type": "application/json"}, body: body)
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final reply =
            decoded['candidates'][0]['content']['parts'][0]['text'];
        setState(() {
          _messages.add({"role": "bot", "text": reply});
          _isLoading = false;
        });
      } else if (response.statusCode == 429) {
        setState(() {
          _messages.add({
            "role": "bot",
            "text":
                "API kotası doldu veya çok fazla istek gönderildi. Lütfen birkaç saniye bekleyip tekrar deneyin."
          });
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          _messages.add({
            "role": "bot",
            "text":
                "API modeli bulunamadı (${response.statusCode}). Lütfen API anahtarınızın Gemini API erişimine sahip olduğundan emin olun."
          });
          _isLoading = false;
        });
      } else {
        setState(() {
          _messages.add({
            "role": "bot",
            "text": "Bir hata oluştu (${response.statusCode}). Lütfen daha sonra tekrar deneyin."
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          "role": "bot",
          "text": "Bağlantı hatası. İnternet bağlantınızı kontrol edin."
        });
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Sohbet Botu"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                return ChatBubble(
                  message: message['text'] ?? "",
                  isUser: isUser,
                  cardColor: cardColor,
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: LinearProgressIndicator(
                color: Colors.indigo,
                backgroundColor: Colors.transparent,
              ),
            ),
          _buildMessageComposer(cardColor),
        ],
      ),
    );
  }

  Widget _buildMessageComposer(Color cardColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(fontSize: 16),
              onSubmitted: (_) => _isLoading ? null : _sendMessage(),
              decoration: InputDecoration(
                hintText: "Bir şeyler yaz...",
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Colors.indigo,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final Color cardColor;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.indigo
              : cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser
                ? const Radius.circular(20)
                : const Radius.circular(4),
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isUser
                ? Colors.white
                : (isDark ? Colors.white : Colors.black87),
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
