import 'package:flutter/material.dart';
import 'Authentication.dart';
import 'HomePageOverflowActions.dart';
import 'SelectContact.dart';
import 'Message.dart';
import 'User.dart';
import 'Group.dart';
import 'ChatPage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'ChatPageOverflowActions.dart';

class HomePage extends StatefulWidget {

  HomePage({
    this.auth,
    this.onSignedOut,
  });
  final AuthImplementation auth;
  final VoidCallback onSignedOut;


  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {

  //Tab variables
  TabController _tabController;

  //AppBar search variables
  final TextEditingController _filter = new TextEditingController();
  String _searchText = "";
  List filteredNames = new List(); // names filtered by search text
  List<User> filteredUsers = new List();
  List<Group> filteredGroups = new List();
  Widget _appBarTitle = new Text('VChat');
  Icon _searchIcon = new Icon(Icons.search);

  //Database variables
  DatabaseReference dbRef;

  String currentUser_uid;
  String currentUser_username;

  List<Message> chat = [];
  List<User> chatUsers = [];
  List<UserChatDetails> chatUsersDetailed = []

  Map<User, int> usersList = new Map<User, int>();

  //Groups variables
  List<Message> groupMessages = [];
  List<Group> groups = [];
  List<Group> userGroups = [];
  Map<User, int> groupList = new Map<User, int>();

  @override
  void initState() {
    super.initState();
    _tabController = new TabController(vsync: this, length: 2);
    _tabController.addListener(_handleTabSelection);

    widget.auth.getCurrentUser().then((firebaseUserId) {
      currentUser_uid = firebaseUserId;
    });

    DatabaseReference dbRef = FirebaseDatabase.instance.reference().child("Chats");

    dbRef.onValue.listen((e) {
      var KEYS = e.snapshot.value.keys;
      var DATA = e.snapshot.value;

      chat.clear();
      chatUsers.clear();

      for(var individualKey in KEYS) {
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

        if (message.type == 'personal'){
          User user = null;
          if (message.sender_uid == currentUser_uid) {
            user = new User(message.recipient_uid, message.recipient);
          }
          else if (message.recipient_uid == currentUser_uid) {
            user = new User(message.sender_uid, message.sender);
          }

          if (user != null && !userListContains(chatUsers, user)) {
            chatUsers.add(user);
          }
          else if (user != null && userListContains(chatUsers, user)) {
            //update timestamp
          }
        }
      }

      setState(() {});
    });


    //Groups
    DatabaseReference groupsRef = FirebaseDatabase.instance.reference().child("Groups");

    groupsRef.onValue.listen((e) {
      var KEYS = e.snapshot.value.keys;
      var DATA = e.snapshot.value;

      groups.clear();
      userGroups.clear();

      for (var individualKey in KEYS) {
        // print(DATA[individualKey]['participants']);
        // print(DATA[individualKey]['participants'][0] is String);
        if (groupParticipantListContains(DATA[individualKey]['participants'], currentUser_uid)) {
          Group group = new Group(
            DATA[individualKey]['groupId'],
            DATA[individualKey]['groupTitle'],
            DATA[individualKey]['participants'],
            DATA[individualKey]['creationDate'],
            DATA[individualKey]['timestamp']
          );
          userGroups.add(group);
        }
      }

      setState(() {});
    });


    filteredUsers = chatUsers;
    filteredGroups = userGroups;

    _filter.addListener(() {
        if (_filter.text.isEmpty) {
          setState(() {
            _searchText = "";
          });
        } else {
          setState(() {
            _searchText = _filter.text;
          });
        }

        filteredUsers = chatUsers;
        filteredGroups = userGroups;

        if (!(_searchText.isEmpty)) {
          List<User> tempList = [];
          List<Group> tempGroupList = [];
          for (int i = 0; i < filteredUsers.length; i++) {
            if (filteredUsers[i].username.toLowerCase().contains(_searchText.toLowerCase())) {
              tempList.add(filteredUsers[i]);
            }
            if (filteredGroups[i].groupName.toLowerCase().contains(_searchText.toLowerCase())) {
              tempGroupList.add(filteredGroups[i]);
            }
          }

          filteredUsers = tempList;
          filteredGroups = tempGroupList;
        }
      });
  }

  bool userListContains(List<User> list, User element) {
    for (var user in list) {
      if (user.userId == element.userId) {
        return true;
      }
    }
    return false;
  }

  bool groupParticipantListContains(List<dynamic> list, String element) {
    for (String user in list) {
      if (user == element) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    setState(() {});
  }

  void _signOut() async {
    try {
      await widget.auth.signOut();
      widget.onSignedOut();
    }
    catch(e) {
      //handle signout failure
    }
  }

  void choiceAction(String choice) {
    if (choice == HomePageOverflowActions.signOut) {
      _signOut();
    }
  }

  void _searchPressed () {
    setState(() {
      if (_searchIcon.icon == Icons.search) {
        _searchIcon = new Icon(Icons.close);
        _appBarTitle = new TextField(
          controller: _filter,
          style: new TextStyle(color: Colors.white),
          decoration: new InputDecoration(
            prefixIcon: new Icon(Icons.search),
            hintText: 'Search...'
          ), //InputDecoration
        ); //TextField
      }
      else {
        _searchIcon = new Icon(Icons.search);
        _appBarTitle = new Text('VChat');
        filteredUsers = chatUsers;
        _filter.clear();
      }
    });
  }

  void floatingActionButtonPressed() {
    if (_tabController.index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return new SelectContact(auth: widget.auth);
          }
        ) //MaterialPageRoute
      ); //Navigator
    }
  }

  void moveToChat(String userId, String username, String chatType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return new ChatPage(auth: widget.auth, recipient_uid: userId, recipient_username: username, chatType: chatType);
        }
      ) //MaterialPageRoute
    ); //Navigator
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
              return HomePageOverflowActions.choices.map((String choice) {
                return PopupMenuItem<String>(value: choice, child: Text(choice));
              }).toList();
            },
          ), //PopupMenuButton
        ], //<Widget>
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(/*icon: Icon(Icons.person),*/ text: "Chats",),
            Tab(/*icon: Icon(Icons.group),*/ text: "Groups"),
          ],
        ),
      ), //AppBar

      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          chatUsers.length != 0
          ? Container(
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (_, index) {
                return UsersUI(filteredUsers[index].userId, filteredUsers[index].username);
              }
            ), //ListView.builder
          )
          :
          Center(
              child: Text ("You haven't started chatting yet!\nClick on the chat button to start a conversation...",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)
            ), //Text
          ), //Center
          userGroups.length != 0
          ? Container(
            child: ListView.builder(
              itemCount: filteredGroups.length,
              itemBuilder: (_, index) {
                return GroupsUI(filteredGroups[index].groupId, filteredGroups[index].groupName);
              }
            ), //ListView.builder
          )
          :
          Center(
              child: Text ("You haven't started chatting yet!\nClick on the chat button to start a conversation...",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold)
            ), //Text
          ), //Center
        ], //<Widget>
      ), //TabBarView

      floatingActionButton: new FloatingActionButton(
        child: Icon((_tabController.index == 0) ? Icons.message : Icons.group_add),

        onPressed: floatingActionButtonPressed,
      ), //FloatingActionButton
    ); //Scaffold
  }

  Widget UsersUI(String userId, String username) {
    return new Card(
        elevation: 10.0,
        margin: EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0, bottom: 5.0),
        shape: new RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ), //RoundedRectangleBorder

        child: new InkWell(
          splashColor: Colors.indigo[200],
          onTap: () {
            moveToChat(userId, username, 'personal');
          },
          child: new Container(
          padding: new EdgeInsets.all(14.0),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              new Text(
                username,
                style: new TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ), //TextStyle
              ), //Text
              new Row(
                children: <Widget>[
                  // new IconButton(
                  //   icon: new Icon(Icons.message),
                  //   onPressed: () {moveToChat(userId, username);},
                  // ), //IconButton
                  PopupMenuButton<String>(
                    onSelected: choiceAction,
                    itemBuilder: (BuildContext context) {
                      return ChatPageOverflowActions.choices.map((String choice) {
                        return PopupMenuItem<String>(value: choice, child: Text(choice));
                      }).toList();
                    },
                  ), //PopupMenuButton
                ],
              ),
            ], //<Widget>
          ), //Row
        ), //Container
      ), //InkWell
    ); //Card
  }

  Widget GroupsUI(String groupId, String groupName) {
    return new Card(
        elevation: 10.0,
        margin: EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0, bottom: 5.0),
        shape: new RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ), //RoundedRectangleBorder

        child: new InkWell(
          splashColor: Colors.indigo[200],
          onTap: () {
            moveToChat(groupId, groupName, 'group');
          },
          child: new Container(
          padding: new EdgeInsets.all(14.0),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              new Text(
                groupName,
                style: new TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ), //TextStyle
              ), //Text
              new Row(
                children: <Widget>[
                  // new IconButton(
                  //   icon: new Icon(Icons.message),
                  //   onPressed: () {moveToChat(userId, username);},
                  // ), //IconButton
                  PopupMenuButton<String>(
                    onSelected: choiceAction,
                    itemBuilder: (BuildContext context) {
                      return ChatPageOverflowActions.choices.map((String choice) {
                        return PopupMenuItem<String>(value: choice, child: Text(choice));
                      }).toList();
                    },
                  ), //PopupMenuButton
                ],
              ),
            ], //<Widget>
          ), //Row
        ), //Container
      ), //InkWell
    ); //Card
  }
}
