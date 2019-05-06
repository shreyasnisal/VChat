import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'User.dart';
import 'Authentication.dart';
import 'ChatPageOverflowActions.dart';
import 'ChatPage.dart';
import 'NewGroupPage.dart';

class SelectContact extends StatefulWidget {

  SelectContact({
    this.auth,
  });

  final AuthImplementation auth;

  @override
  _SelectContactState createState() => new _SelectContactState();
}

class _SelectContactState extends State<SelectContact> {

  bool _loading = true;
  bool _longPressedFlag = false;

  String currentUser_uid;

  //AppBar search variables
  final TextEditingController _filter = new TextEditingController();
  String _searchText = "";
  List filteredNames = new List(); // names filtered by search text
  List<User> filteredUsers = [];
  Widget _appBarTitle = new Text('Select Contact(s)');
  Icon _searchIcon = new Icon(Icons.search);
  FocusNode searchField_focusNode = new FocusNode();

  List<User> usersList = [];

  //Group variables
  List<User> groupList = [];

  @override
  void initState() {
    super.initState();

    widget.auth.getCurrentUser().then((firebaseUserId) {
      currentUser_uid = firebaseUserId;
    });

    DatabaseReference usersRef = FirebaseDatabase.instance.reference().child("Users");
    usersRef.keepSynced(true);

    usersRef.onValue.listen((e) {
      var KEYS = e.snapshot.value.keys;
      var DATA = e.snapshot.value;

      usersList.clear();

      for(var individualKey in KEYS) {
        User user = new User(
          DATA[individualKey]['userId'],
          DATA[individualKey]['username'],
        );
        if (user.userId != currentUser_uid) {
          usersList.add(user);
        }
      }

      usersList.sort((a, b) => a.username.compareTo(b.username));

      setState(() {
        _loading = false;
      });
    });

    filteredUsers = usersList;

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

      filteredUsers = usersList;

      List<User> tempList = [];
      for (int i = 0; i < filteredUsers.length; i++) {
        if (filteredUsers[i].username.toLowerCase().contains(_searchText.toLowerCase())) {
          tempList.add(filteredUsers[i]);
        }
      }

      filteredUsers = tempList;
    });
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
        _appBarTitle = new Text('Select Contact(s)');
        filteredUsers = usersList;
        _filter.clear();
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

  void removeUserFromList(List<User> list, User element) {
    User user;
    for (user in list) {
      if (user.userId == element.userId) {
        break;
      }
    }
    list.remove(user);
  }

  void choiceAction(String choice) {

  }

  void contactTapped(String userId, String username) {
    if (_longPressedFlag) {
      User user = new User(userId, username);
      if (!userListContains(groupList, user)) {
        groupList.add(user);
        setState(() => {
          _appBarTitle = new Text('${groupList.length} Contact(s) Selected')
        });
      }
      else {
        removeUserFromList(groupList, user);
        setState(() => {
          _appBarTitle = new Text('${groupList.length} Contact(s) Selected')
        });
        if (groupList.length == 0) {
          setState(() {
            _longPressedFlag = false;
            _appBarTitle = new Text('Select Contact(s)');
          });
        }
      }
    }
    else {
      moveToChat(userId, username);
    }
  }

  void contactLongPressed(String userId, String username) {
    User user = new User(userId, username);
    if (!userListContains(groupList, user)) {
      groupList.add(user);
      setState(() {
        _longPressedFlag = true;
        _appBarTitle = new Text('${groupList.length} Contact(s) Selected');
      });
    }
    else {
      removeUserFromList(groupList, user);
      setState(() => {
        _appBarTitle = new Text('${groupList.length} Contact(s) Selected')
      });
      if (groupList.length == 0) {
        setState(() {
          _longPressedFlag = false;
          _appBarTitle = new Text("Select Contact(s)");
        });
      }
    }
  }

  void moveToChat(String userId, String username) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return new ChatPage(auth: widget.auth, recipient_uid: userId, recipient_username: username, chatType: 'personal');
        }
      ) //MaterialPageRoute
    ); //Navigator
  }

  void moveToNewGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        maintainState: false,
        builder: (context) {
          return new NewGroupPage(auth: widget.auth, participants: groupList);
        }
      ) //MaterialPageRoute
    ); //Navigator
  }

  //Design
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: _appBarTitle,
        automaticallyImplyLeading: false,
        // centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: _searchIcon,
            onPressed: _searchPressed,
          ),
          // PopupMenuButton<String>(
          //   onSelected: choiceAction,
          //   itemBuilder: (BuildContext context) {
          //     return HomePageOverflowActions.choices.map((String choice) {
          //       return PopupMenuItem<String>(value: choice, child: Text(choice));
          //     }).toList();
          //   },
          // ), //PopupMenuButton
        ], //<Widget>
      ), //AppBar

      body: _loading
        ? Center(
          child: CircularProgressIndicator(),
        )
        : new Container(
          child: usersList.length == 0
            ? Center(
              child: new Text("No users to display")
            )
            : new ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (_, index) {
                return UsersUI(filteredUsers[index].userId, filteredUsers[index].username);
              }
            ), //ListView.builder
        ), //Container

      floatingActionButton: groupList.length == 0
        ? null
        : new FloatingActionButton(
          child: Icon(Icons.group_add),
          onPressed: moveToNewGroup,
        ), //FloatingActionButton
    ); //Scaffold
  }

  Widget UsersUI(String userId, String username) {
    return new Card(
      elevation: 10.0,
      color: userListContains(groupList, new User(userId, username)) ? Colors.indigo[200] : Colors.white,
      margin: EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0, bottom: 5.0),
      shape: new RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        // side: new BorderSide(
        //   color: userListContains(groupList, new User(userId, username)) ? Colors.indigo : Colors.transparent,
        //   width: 3.0,
        // ), //BorderSide
      ), //RoundedRectangleBorder

      child: new InkWell(
        splashColor: Colors.indigo[200],
        onTap: () {
          contactTapped(userId, username);
        },
        onLongPress: () {
          contactLongPressed(userId, username);
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
                ),
              ), //Text
              new Row(
                children: <Widget>[
                  // new IconButton(
                  //   icon: new Icon(Icons.message),
                  //   onPressed: () {moveToChat(userId, username);},
                  // ), //IconButton
                  (userListContains(groupList, new User(userId, username)))
                  ? new Icon(Icons.check_circle)
                  : new SizedBox(height: 0),
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
