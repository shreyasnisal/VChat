import 'package:flutter/Material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'Authentication.dart';
import 'User.dart';
import 'package:intl/intl.dart';
import 'package:random_string/random_string.dart';
import 'ChatPage.dart';


class NewGroupPage extends StatefulWidget {

  NewGroupPage({
    this.auth,
    this.participants,
  });

  final AuthImplementation auth;
  List<User> participants;

  @override
  _NewGroupState createState() => new _NewGroupState();
}

class _NewGroupState extends State<NewGroupPage> {

  String _groupName = "";
  List<User> participants = [];

  String currentUser_username;
  String currentUser_uid;

  //Methods
  @override
  void initState() {
    super.initState();

    widget.auth.getCurrentUser().then((userId) {
      currentUser_uid = userId;
    });
    widget.auth.getCurrentUser_username().then((username) {
      currentUser_username = username;
    });

    for (var user in widget.participants) {
      participants.add(user);
    }
  }

  void removeUserFromList(List<User> list, User element) {
    User user;
    for (user in list) {
      if (user.userId == element.userId) {
        break;
      }
    }
    list.remove(user);
    setState(() {});
  }

  void createGroup() {
    var group_id = randomAlphaNumeric(13);
    var dbTimeKey = new DateTime.now().toUtc();
    int timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;
    var formatDate = new DateFormat('MMM d, yyyy');
    var creationDate = formatDate.format(dbTimeKey);
    DatabaseReference dbRef = FirebaseDatabase.instance.reference();
    List<String> participant_uids = [];
    for (var participant in participants) {
      participant_uids.add(participant.userId);
    }
    participant_uids.add(currentUser_uid);

    var data = {
      "groupId": group_id,
      "createdBy": currentUser_username,
      "participants": participant_uids,
      "timestamp": timestamp,
      "creationDate": creationDate.toString(),
      "groupTitle": _groupName
    };
    dbRef.child("Groups").push().set(data);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return new ChatPage(auth: widget.auth, recipient_uid: group_id, recipient_username: _groupName, chatType: 'group');
        }
      ) //MaterialPageRoute
    ); //Navigator
  }

  //Design
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text('New Group'),
        automaticallyImplyLeading: false,
      ), //AppBar

      body: new Container(
        margin: EdgeInsets.only(left: 15.0, right: 15.0, top: 30.0),
        child: new Column(
          children: <Widget>[
            new TextField(
              decoration: new InputDecoration(
                hintText: 'Enter Group Name'
              ), //InputDecoration
              onChanged: (value) {
                setState(() {_groupName = value;});
              },
            ), //TextField

            new Container(
              margin: EdgeInsets.only(top: 20.0),
              child: new Text(
                'Participants: ${participants.length}',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ), //Text
            ), //Container

            new Container(
              child: participants.length == 0
                ? Center(
                  child: new Text("No participants")
                )
                : new Expanded( child: new ListView.builder(
                  itemCount: participants.length,
                  itemBuilder: (_, index) {
                    return UsersUI(participants[index].userId, participants[index].username);
                  }
                ), //ListView.builder
              ), //Expanded
            ), //Container
          ], //<Widget>
        ), //Column
      ), //Container

      floatingActionButton: _groupName == "" || participants.length == 0
        ? null
        : new FloatingActionButton(
          child: Icon(Icons.check),
          onPressed: createGroup,
        ), //FloatingActionButton
    ); //Scaffold
  }


  Widget UsersUI(String userId, String username) {
    return new Card(
      elevation: 10.0,
      margin: EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0, bottom: 5.0),
      shape: new RoundedRectangleBorder(
        borderRadius: new BorderRadius.circular(15.0)
      ), //RoundedRectangleBorder

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
                  new IconButton(
                    icon: new Icon(Icons.close),
                    onPressed: () {
                      removeUserFromList(participants, new User(userId, username));
                    },
                  ), //IconButton
                  // PopupMenuButton<String>(
                  //   onSelected: choiceAction,
                  //   itemBuilder: (BuildContext context) {
                  //     return ChatPageOverflowActions.choices.map((String choice) {
                  //       return PopupMenuItem<String>(value: choice, child: Text(choice));
                  //     }).toList();
                  //   },
                  // ), //PopupMenuButton
                ],
              ),
            ], //<Widget>
          ), //Row
        ), //Container
    ); //Card
  }
}
