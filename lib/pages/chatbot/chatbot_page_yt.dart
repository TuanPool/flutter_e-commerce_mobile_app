import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:ecommerece_flutter_app/common/constants/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/product.dart';
import '../product_detail/product_detail.dart';

// 🔑 API Key Gemini
const String geminiApiKey = 'AIzaSyABQnk7w_3FyltOeptVCy6OzrHU9yQjOoI';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatUser _currentUser =
      ChatUser(id: '1', firstName: '', lastName: 'User');
  final ChatUser _gptChatUser =
      ChatUser(id: '2', firstName: 'Chat', lastName: 'Bot');

  List<ChatMessage> _messages = [];
  List<ChatUser> _typingUsers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: KColors.primaryColor,
        automaticallyImplyLeading: false,
        title: const Text(
          'Chatbot',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: DashChat(
        currentUser: _currentUser,
        typingUsers: _typingUsers,
        messageOptions: MessageOptions(
          currentUserContainerColor: const Color.fromARGB(98, 0, 0, 0),
          containerColor: KColors.primaryColor,
          textColor: Colors.white,
          parsePatterns: [
            MatchText(
              type: ParsedType.URL,
              style: const TextStyle(
                color: Colors.yellowAccent,
                decoration: TextDecoration.underline,
              ),
              onTap: (url) => _handleLink(url),
            ),
            MatchText(
              pattern: r'(product://detail/\w+)',
              style: const TextStyle(
                color: Colors.lightBlueAccent,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.bold,
              ),
              onTap: (url) => _handleLink(url),
            ),
          ],
        ),
        onSend: (ChatMessage message) {
          getChatResponse(message);
        },
        messages: _messages,
      ),
    );
  }

  Future<void> getChatResponse(ChatMessage userMessage) async {
    setState(() {
      _messages.insert(0, userMessage);
      _typingUsers.add(_gptChatUser);
    });

    try {
      final productLines = await fetchProductPromptLines();

      final productTextList = productLines.map((product) {
        final id = product['id'];
        final name = product['name'];
        final price = product['price'];
        final sale = product['salePercent'];

        return '''
Sản phẩm:
- Name: $name
- Price: ${price}đ
- Discount: $sale%
- Link: product://detail/$id
''';
      }).join("\n");

      final systemPrompt = '''
Bạn là một trợ lý thân thiện chuyên tư vấn sản phẩm trong cửa hàng thương mại điện tử.

Hãy trả lời ngắn gọn, thân thiện và chỉ giới thiệu **tối đa 3 sản phẩm** mỗi lần.  
Mỗi sản phẩm cần có:
- Tên sản phẩm
- Giá (đơn vị: VND) 
- Giảm giá (nếu có)
- Link đúng định dạng: product://detail/[id sản phẩm]

Danh sách sản phẩm hiện có:
$productTextList
''';

      final messages = [
        {
          "role": "user",
          "parts": [
            {"text": "$systemPrompt\n\nNgười dùng: ${userMessage.text}"}
          ]
        }
      ];

      // Gọi Gemini API
      final response = await http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$geminiApiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"contents": messages}),
      );

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        final reply = decoded['candidates']?[0]?['content']?['parts']?[0]
                ?['text'] ??
            'Xin lỗi, tôi không hiểu yêu cầu của bạn.';

        setState(() {
          _messages.insert(
            0,
            ChatMessage(
              user: _gptChatUser,
              createdAt: DateTime.now(),
              text: reply,
            ),
          );
        });
      } else {
        _handleError("Lỗi API Gemini: ${decoded['error'] ?? decoded}");
      }
    } catch (e) {
      _handleError("Lỗi: $e");
    } finally {
      setState(() {
        _typingUsers.remove(_gptChatUser);
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchProductPromptLines() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .limit(100)
        .get();

    List<Map<String, dynamic>> productDataList = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      productDataList.add({
        "id": doc.id,
        "name": data['name'] ?? '',
        "description": data['description'] ?? '',
        "price": data['priceProduct'] ?? '',
        "salePercent": data['salePercent'] ?? '',
        "link": "product://detail/${doc.id}",
      });
    }

    return productDataList;
  }

  void _handleError(String errorMessage) {
    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          user: _gptChatUser,
          createdAt: DateTime.now(),
          text: errorMessage,
        ),
      );
    });
  }

  void _handleLink(String url) async {
    if (url.startsWith("product://detail/")) {
      final productId = url.split("/").last;
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();

      if (!doc.exists) return;

      final product = Product.fromMap(doc.data()!, doc.id);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetail(
            rateProduct: "4.8",
            product: product,
          ),
        ),
      );
    } else if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}
