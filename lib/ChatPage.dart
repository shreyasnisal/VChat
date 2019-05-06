import 'package:flutter/material.dart';
import 'ChatPageOverflowActions.dart';
import 'Authentication.dart';
import 'dart:io';
import 'dart:core';
import 'package:firebase_database/firebase_database.dart';
import 'Message.dart';
import 'package:intl/intl.dart';
import 'package:flutter/scheduler.dart';

enum ChatType {personal, group}

class ChatPage extends StatefulWidget {

  ChatPage({
    this.auth,
    this.recipient_uid,
    this.recipient_username,
    this.chatType
  });

  final String recipient_username;
  final String recipient_uid;
  final AuthImplementation auth;
  final String chatType;

  @override
  _ChatPageState createState() => new _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  bool _loading = false;
  String _message = "";

  ChatType _chatType;

  final TextEditingController _message_controller = new TextEditingController();
  final ScrollController _chatScroll = new ScrollController();

  //AppBar search variables
  final TextEditingController _filter = new TextEditingController();
  String _searchText = "";
  List names = new List(); // names we get from API
  List filteredNames = new List(); // names filtered by search text
  Widget _appBarTitle;
  Icon _searchIcon = new Icon(Icons.search);

  List<Message> chat = [];

  String _prevMessage_date = "";

  //Database variables
  DatabaseReference chatRef;

  String currentUser_uid;
  String currentUser_username;

  FocusNode _message_focusNode = new FocusNode();

  @override
  void initState() {
    super.initState();

    _chatType = (widget.chatType == "personal") ? ChatType.personal : ChatType.group;

    _appBarTitle = new Text(widget.recipient_username);

    widget.auth.getCurrentUser().then((firebaseUserId) {
      currentUser_uid = firebaseUserId;
    });

    DatabaseReference usersRef = FirebaseDatabase.instance.reference().child("Users");
    usersRef.once().then((DataSnapshot snap) {
      var KEYS = snap.value.keys;
      var DATA = snap.value;

      for (var individualKey in KEYS) {
        if (DATA[individualKey]['userId'] == currentUser_uid) {
          currentUser_username = DATA[individualKey]['username'];
        }
      }
    });

    chatRef = FirebaseDatabase.instance.reference().child("Chats");
    chatRef.keepSynced(true);

    chatRef.onValue.listen((e) {
      var KEYS = e.snapshot.value.keys;
      var DATA = e.snapshot.value;

      chat.clear();

      for(var individualKey in KEYS) {


        if (_chatType == ChatType.personal) {
          if (DATA[individualKey]['sender_uid'] != currentUser_uid.toString() && DATA[individualKey]['recipient_uid'] != currentUser_uid) {
            continue;
          }
          else if (DATA[individualKey]['sender_uid'] == currentUser_uid.toString() && DATA[individualKey]['recipient_uid'] != widget.recipient_uid) {
            continue;
          }
          else if (DATA[individualKey]['recipient_uid'] == currentUser_uid.toString() && DATA[individualKey]['sender_uid'] != widget.recipient_uid) {
            continue;
          }
        }
        else {
          if (DATA[individualKey]['recipient_uid'] != widget.recipient_uid) {
            continue;
          }
        }

        int msFromEpoch = int.parse(DATA[individualKey]['timestamp']);
        var date = DateTime.fromMillisecondsSinceEpoch(msFromEpoch);
        String dateString = new DateFormat('MMM d, yyyy').format(date);
        String timeString = new DateFormat('hh:mm aa').format(date);

        Message message = new Message(
          DATA[individualKey]['timestamp'],
          DATA[individualKey]['message'],
          DATA[individualKey]['sender_uid'],
          DATA[individualKey]['sender'],
          DATA[individualKey]['recipient_uid'],
          DATA[individualKey]['recipient'],
          dateString,
          timeString,
          DATA[individualKey]['status'],
          DATA[individualKey]['type']
        );
        chat.add(message);
      }

      // chat.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      chat.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      // usersList.sort((a, b) => a.username.compareTo(b.username));


      // _message_focusNode.addListener(() {
      //   print(_message_focusNode.hasFocus);
      //   if (_message_focusNode.hasFocus) {
      //
      //   }
      // });

      setState(() {
        _loading = false;
      });
    });
  }

  void _searchPressed () {
    setState(() {
      if (_searchIcon.icon == Icons.search) {
        _searchIcon = new Icon(Icons.close);
        _appBarTitle = new TextField(
          controller: _filter,
          decoration: new InputDecoration(
            prefixIcon: new Icon(Icons.search),
            hintText: 'Search...'
          ), //InputDecoration
        ); //TextField
      }
      else {
        _searchIcon = new Icon(Icons.search);
        _appBarTitle = new Text(widget.recipient_username);
        filteredNames = names;
        _filter.clear();
      }
    });
  }

  void choiceAction(String choice) {

  }

  void _sendMessage() {
    if (_message != "") {
      var dbTimeKey = new DateTime.now().toUtc();
      int timestamp = new DateTime.now().toUtc().millisecondsSinceEpoch;
      var formatDate = new DateFormat('MMM d, yyyy');
      var formatTime = new DateFormat('EEEE, hh:mm aaa');

      String date = formatDate.format(dbTimeKey);
      String time = formatTime.format(dbTimeKey);

      var data = {
        "timestamp": timestamp.toString(),
        "message": _message,
        "sender_uid": currentUser_uid,
        "sender": currentUser_username,
        "recipient_uid": widget.recipient_uid,
        "recipient": widget.recipient_username,
        "date": date,
        "time": time,
        "status": "sent",
        "type": widget.chatType,
      };

      chatRef.push().set(data).then((e) {
        _message = "";
        setState(() {
          _message_controller.clear();
        });
        _chatScroll.animateTo(
          0.0,
          duration: new Duration(milliseconds: 200),
          curve: Curves.easeOut
        );
      });
    }
  }

  //Design
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: _appBarTitle,
        automaticallyImplyLeading: false,
        // centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: _searchIcon,
            onPressed: _searchPressed,
          ),
          PopupMenuButton<String>(
            onSelected: choiceAction,
            itemBuilder: (BuildContext context) {
              return ChatPageOverflowActions.choices.map((String choice) {
                return PopupMenuItem<String>(value: choice, child: Text(choice));
              }).toList();
            },
          ), //PopupMenuButton
        ], //<Widget>
      ), //AppBar

      body: _loading
      ? Center(
        child: CircularProgressIndicator()
      )
      : new Container(
        // reverse: true,
        child: new Column(
          children: <Widget>[
          new Expanded(
            child: new ListView.builder(
              reverse: true,
              controller: _chatScroll,
              itemCount: chat.length,
              itemBuilder: (_, index) {
                return (index != chat.length - 1 && chat[index].date == chat[index+1].date) ? ChatUI(chat[index].message, chat[index].sender_uid, chat[index].sender, chat[index].time) : ChatUIWithDate(chat[index].message, chat[index].sender_uid, chat[index].sender, chat[index].date, chat[index].time);
              }
            ), //ListView.builder
          ), //Container
          new TextField(
            // autofocus: true,
            controller: _message_controller,
            focusNode: _message_focusNode,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.send,
            onTap: () {
              _chatScroll.animateTo(
                0.0,
                duration: new Duration(milliseconds: 200),
                curve: Curves.easeOut
              );
            },
            decoration: new InputDecoration(
              border: OutlineInputBorder(
                borderRadius: new BorderRadius.circular(25.0),
                borderSide: new BorderSide(
                  color: Colors.grey,
                ), //BorderSide
              ), //OutlineInputBorder
              focusedBorder: OutlineInputBorder(
                borderRadius: new BorderRadius.circular(25.0),
                borderSide: new BorderSide(
                  color: Colors.grey,
                ), //BorderSide
              ), //OutlineInputBorder
              hintText: "Type a message",
              suffixIcon: new IconButton(
                icon: new Icon(Icons.send),
                onPressed: _sendMessage,
              ), //IconButton
            ), //TextFieldDecoration
            onChanged: (value) {
              _message = value;
            },
            onEditingComplete: _sendMessage,
          ), //TextField
        ],
        ), //ListView
      ),
    );
  }

  Widget ChatUIWithDate(String message, String sender_uid, String sender, String date, String time) {
    return new Container(
      padding: new EdgeInsets.only(left: 10.0, right: 10.0),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new Card(
                color: Colors.deepPurple[300],
                child: new Container(
                  margin: EdgeInsets.all(5.0),
                  child: new Text(date, style: TextStyle(fontSize: 20.0, color: Colors.white),),
                ), //Container
              ), //Card
            ], ///Widget
          ), //Row
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: sender_uid == currentUser_uid ? MainAxisAlignment.end : MainAxisAlignment.start,
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              new Flexible(
                child: new Card(
                  shape: new RoundedRectangleBorder(
                    borderRadius: sender_uid == currentUser_uid
                      ? BorderRadius.only(
                          topLeft: Radius.circular(15.0),
                          topRight: Radius.circular(15.0),
                          bottomLeft: Radius.circular(15.0),
                        ) //BorderRadius
                      : BorderRadius.only(
                        topLeft: Radius.circular(15.0),
                        topRight: Radius.circular(15.0),
                        bottomRight: Radius.circular(15.0),
                      )
                  ), //RoundedRectangleBorder
                  color: sender_uid == currentUser_uid ? Colors.blue : Colors.cyan,
                  child: new Container(
                    margin: EdgeInsets.all(8.0),
                    child: new Column(
                      children: <Widget>[
                        new Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            new Text(time, style: TextStyle(fontSize: 12.0, color: Colors.white)),
                          ], //<Widget>
                        ), //Row
                        new Text(message, style: TextStyle(fontSize: 22.0, color: Colors.white)),
                        new Row(
                          children: <Widget>[
                            new Text(sender, style:TextStyle(fontSize: 16.0, color: Colors.white)),
                          ], //<Widget>
                        ), //Row
                      ], //<Widget>
                    ), //Column
                  ), //Container
                ), //Card
              ), //Flexible
            ], //<Widget>
          ), //Row
        ], //<Widget>
      ), //Column
    ); //Container
  }

  Widget ChatUI(String message, String sender_uid, String sender, String time) {
    return new Container(
      padding: new EdgeInsets.only(left: 10.0, right: 10.0),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: sender_uid == currentUser_uid ? MainAxisAlignment.end : MainAxisAlignment.start,
            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              new Flexible(
                fit: FlexFit.loose,
                child:new Card(
                  shape: new RoundedRectangleBorder(
                    borderRadius: sender_uid == currentUser_uid
                      ? BorderRadius.only(
                          topLeft: Radius.circular(15.0),
                          topRight: Radius.circular(15.0),
                          bottomLeft: Radius.circular(15.0),
                        ) //BorderRadius
                      : BorderRadius.only(
                        topLeft: Radius.circular(15.0),
                        topRight: Radius.circular(15.0),
                        bottomRight: Radius.circular(15.0),
                      )
                  ), //RoundedRectangleBorder
                  color: sender_uid == currentUser_uid ? Colors.blue : Colors.cyan,
                  child: new Container(
                    margin: EdgeInsets.all(8.0),
                    child: new Column(
                      children: <Widget>[
                        new Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            new Text(time, style: TextStyle(fontSize: 12.0, color: Colors.white)),
                          ], //<Widget>
                        ), //Row
                        new Text(message, style: TextStyle(fontSize: 22.0, color: Colors.white)),
                        (_chatType == ChatType.group && sender_uid != currentUser_uid)
                        ? new Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            new Text(sender, style:TextStyle(fontSize: 16.0, color: Colors.white)),
                          ], //<Widget>
                        ) //Row
                        : SizedBox(height: null),
                      ], //<Widget>
                    ), //Column
                  ), //Container
                ), //Card
              ), //Flexible
            ], //<Widget>
          ), //Row
        ], //<Widget>
      ), //Column
    ); //Container
  }
}
