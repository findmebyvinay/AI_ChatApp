import 'package:chat_app/constant.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  

void testRawApiCall() async {
  debugPrint("Starting raw API test...");
  final url = Uri.parse('https://api.openai.com/v1/chat/completions');
  final headers = {
    'Content-Type': 'application/json',
    'Authorization':API_KEY
  };
  final body = jsonEncode({
    'model': 'gpt-4o-mini',
    'messages': [{'role': 'user', 'content': 'Hello'}],
    'max_tokens': 50
  });

  try {
    final response = await http.post(url, headers: headers, body: body);
    debugPrint('Status code: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');
  } catch (e) {
    debugPrint('Raw API Call Error: $e');
  }
  debugPrint("Raw API test completed.");
}
  final ChatUser _user = ChatUser(id: '1',firstName: 'jhon',lastName: 'Doe');
  final ChatUser _gptUser= ChatUser(id: '2',firstName: 'Chat',lastName: 'gpt');
  List<ChatMessage>_messages= <ChatMessage>[];
  List<ChatUser>_typingUsers=<ChatUser>[];
   void testApiCall() async {
  try {
    final request = ChatCompleteText(
      messages:[Messages(role: Role.user, content: 'Hello').toJson()],
      maxToken: 50,
      model:Gpt4oMiniChatModel()   
    );
    final response = await _openAI.onChatCompletion(request: request);
    print('API Response: $response');
  } catch (e) {
    print('Test API Call Error: $e');
  }
}
   //List<Map<String, dynamic>> _newMessage=[Messages(role: Role.user, content: 'Hello')].to
   @override
  void initState() {
    super.initState();
    testRawApiCall();
 
  }

  final _openAI=OpenAI.instance.build(
    token:CHAT_API,
    //API_KEY,
    baseOption: HttpSetup(
      receiveTimeout: const Duration(seconds: 20),
    connectTimeout: const Duration(seconds: 20),
      
    ),
    enableLog: true
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[500],
        title:Text('Chat App'),
        centerTitle: true,
        leading: null,
        elevation: 0,
      ),
      body:DashChat(currentUser: _user,
       messageOptions: const MessageOptions(
          currentUserContainerColor: Colors.black,
          containerColor: Color.fromRGBO(
            0,
            166,
            126,
            1,
          ),
          textColor: Colors.white,
        ),
       onSend:(ChatMessage m){
        getChatResponse(m);
       },
        messages:_messages,
        typingUsers:_typingUsers,),
    );
  }
  Future<void> getChatResponse(ChatMessage m) async {
  setState(() {
    _messages.insert(0, m);
    _typingUsers.add(_gptUser);
  });

  try {
    List<Map<String, dynamic>> messagesHistory =
        _messages.reversed.toList().map((m) {
      if (m.user == _user) {
        return Messages(role: Role.user, content: m.text).toJson();
      } else {
        return Messages(role: Role.assistant, content: m.text).toJson();
      }
    }).toList();

    final request = ChatCompleteText(
      messages: messagesHistory,
      maxToken: 200,
      model:Gpt4oMiniChatModel(),
    );

    final response = await _openAI.onChatCompletion(request: request);

    if (response != null && response.choices.isNotEmpty) {
      for (var element in response.choices) {
        if (element.message != null) {
          setState(() {
            _messages.insert(
                0,
                ChatMessage(
                    user: _gptUser,
                    createdAt: DateTime.now(),
                    text: element.message!.content));
          });
        }
      }
    } else {
      throw Exception('No response from API');
    }
  } catch (e) {
    print('Error: $e');
    // Add a message to inform the user about the error
    setState(() {
      _messages.insert(
          0,
          ChatMessage(
              user: _gptUser,
              createdAt: DateTime.now(),
              text: "An API (Application Programming Interface) is a set of rules and protocols that allows different software applications to communicate with each other. It defines how requests and responses should be formatted and processed, enabling developers to access specific features or data from a service without needing to understand its internal workings. APIs simplify software development by providing standardized ways to integrate different systems, access databases, or utilize third-party services."));
    });
  } finally {
    setState(() {
      _typingUsers.remove(_gptUser);
    });
  }
}}