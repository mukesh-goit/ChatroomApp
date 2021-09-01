import 'package:encrypt/encrypt.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flash_chat/components/encrypter.dart';

final _cloud = Firestore.instance;
FirebaseUser loggedInUser;

class ChatScreen extends StatefulWidget {
  static String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String encryptedText;
  String messageText;
  final messageController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) loggedInUser = user;
      print(loggedInUser.email);
    } catch (e) {
      print(e);
    }
  }

//  void messagesStream()async{
//    await for(var snapshot in _cloud.collection('messages').snapshots())
//      for(var message in snapshot.documents)
//        print(message.data);
//  }
  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                //messagesStream();
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('Chat'),
        backgroundColor: Colors.black45,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      onChanged: (value) {
                        //Do something with the user input.
                        var encrypter = Encrypt(plainText: value); //encryption
                        messageText = value;
                        encryptedText = encrypter.encryption();
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      messageController.clear();
                      _cloud.collection('messages').add({
                        'text': encryptedText,
                        'sender': loggedInUser.email,
                        'time': FieldValue.serverTimestamp()

                      });
                      print(encryptedText);
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  var encrypter = Encrypt();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _cloud
          .collection('messages')
          .orderBy('time', descending: false)
          .snapshots(),
      // ignore: missing_return
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }
        final messages = snapshot.data.documents.reversed;
        List<MessageBubble> messageBubbles = [];
        final currentUser = loggedInUser.email;
        for (var message in messages) {
          final String messageText = message.data['text'];
          final messageSender = message.data['sender'];
          final messageTime = message.data['time'] as Timestamp;
          dynamic messageBubble;
          Encrypted encrypt = Encrypted.fromBase64(messageText); //decryption
          String plainText = Encrypt().decryption(encrypt);
          String cipherText = messageText;
          messageBubble = MessageBubble(
              cipherText: cipherText,
              plainText: plainText,
              sender: messageSender,
              isMe: currentUser == messageSender,
              time: messageTime);
          messageBubbles.add(messageBubble);
        }
        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String cipherText, plainText;
  final String sender;
  final bool isMe;
  final Timestamp time;
  MessageBubble(
      {this.cipherText, this.plainText, this.sender, this.isMe, this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sender,
            style: TextStyle(fontSize: 12.0, color: Colors.black54),
          ),
          Material(
            borderRadius: isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(23.0),
                    bottomLeft: Radius.circular(23.0),
                    bottomRight: Radius.circular(23.0))
                : BorderRadius.only(
                    topRight: Radius.circular(23.0),
                    bottomLeft: Radius.circular(23.0),
                    bottomRight: Radius.circular(23.0)),
            color: isMe ? Colors.lightBlueAccent : Colors.black26,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10,10,10,10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$cipherText',
                    style: TextStyle(
                        fontSize: 15.0,
                        color: Colors.white),
                  ),
                  Text(
                    '$plainText',
                    style: TextStyle(
                        fontSize: 15.0,
                        color: Colors.black87),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
