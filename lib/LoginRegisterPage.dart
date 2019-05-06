import 'package:flutter/material.dart';
import 'Authentication.dart';
import 'DialogBox.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class LoginRegisterPage extends StatefulWidget {

  LoginRegisterPage({
    this.auth,
    this.onSignedIn,
  });
  final AuthImplementation auth;
  final VoidCallback onSignedIn;

  State<StatefulWidget> createState() {
    return _LoginRegisterState();
  }
}

enum FormType {login, register}

class _LoginRegisterState extends State<LoginRegisterPage> {

  DialogBox dialogBox = new DialogBox();

  final formKey = new GlobalKey<FormState>();
  FormType _formType = FormType.login;
  String _email = "";
  String _password = "";
  String _username = "";
  bool _loading = false;

  Icon _passwordIcon = new Icon(Icons.visibility_off);
  bool _hidePassword = true;

  FocusNode username_focusNode = new FocusNode();
  FocusNode email_focusNode = new FocusNode();
  FocusNode password_focusNode = new FocusNode();

  //Methods
  bool validateAndSave() {
    final form = formKey.currentState;

    if (form.validate()) {
      form.save();
      return true;
    }
    else {
      return false;
    }
  }

  void validateAndSubmit() async {

    String userId;

    if (validateAndSave()) {
      setState(() {
        _loading = true;
      });

      try {
        if (_formType == FormType.login) {
          userId = await widget.auth.signIn(_email, _password);
        }
        else {
          userId = await widget.auth.signUp(_email, _password);
          saveUserToDatabase(userId);
        }
        widget.onSignedIn();
      }
      catch(e) {
        dialogBox.information(context, "Error", "Could not process request");
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void saveUserToDatabase(userId) {
    DatabaseReference dbReference = FirebaseDatabase.instance.reference();
    var data = {
      "userId": userId,
      "username": _username,
    };

    dbReference.child("Users").push().set(data);
  }

  void moveToRegister() {
    FocusScope.of(context).requestFocus(new FocusNode());
    formKey.currentState.reset();

    setState(() {
      _formType = FormType.register;
    });
  }

  void moveToLogin() {
    FocusScope.of(context).requestFocus(new FocusNode());
    formKey.currentState.reset();

    setState(() {
      _formType = FormType.login;
    });
  }

  void togglePasswordVisibility() {
    setState(() {
      _hidePassword = !_hidePassword;
      if (_passwordIcon.icon == Icons.visibility) {
        _passwordIcon = new Icon(Icons.visibility_off);
      }
      else {
        _passwordIcon = new Icon(Icons.visibility);
      }
    });
  }

  //Design
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      //resizeToAvoidBottomPadding: false,

      appBar: new AppBar(
        title: (_formType == FormType.login) ? Text("Login") : Text("Register"),
        centerTitle: true,
      ), //AppBar

      body: _loading
      ? Center(
        child: CircularProgressIndicator(),
      )
      :new Center(child: new ListView(
        //margin: EdgeInsets.all(15.0),
        reverse: true,
        children: <Widget>[
          new Form(
            key: formKey,
            child: new Container(
              padding: EdgeInsets.only(left: 15.0, right: 15.0),
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: createInputs() + createButtons()
              ), //Column
            ), //Container
          ), //Form
        ].reversed.toList(),
      ), //ListView
    )
    ); //Scaffold
  }

  List<Widget> createInputs() {
    return[
      SizedBox(height: 10.0),
      logo(),
      SizedBox(height: 20.0),

      (_formType == FormType.register)
      ? new TextFormField (
        focusNode: username_focusNode,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        decoration: new InputDecoration(labelText: 'Full Name'),
        validator: (value) {
          return value.isEmpty ? 'Please enter name' : null;
        },
        onSaved: (value) {
          return _username = value;
        },
        onEditingComplete: () {
          FocusScope.of(context).requestFocus(email_focusNode);
        },
      )
      : SizedBox(height: 0.0),

      new TextFormField(
        focusNode: email_focusNode,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        decoration: new InputDecoration(labelText: 'Email'),

        validator: (value) {
          return value.isEmpty ? 'Please enter email' : null;
        },

        onSaved: (value) {
          return _email = value;
        },
        onEditingComplete: () {
          FocusScope.of(context).requestFocus(password_focusNode);
        }
      ), //TextFormField

      SizedBox(height: 10.0),

      new TextFormField(
        focusNode: password_focusNode,
        textInputAction: TextInputAction.done,
        decoration: new InputDecoration(
          labelText: 'Password',
          suffixIcon: new IconButton(
            icon: _passwordIcon,
            onPressed: togglePasswordVisibility,
          ), //IconButton
        ), //InputDecoration
        obscureText: _hidePassword,

        validator: (value) {
          return value.isEmpty ? 'Please enter password' : null;
        },

        onSaved: (value) {
          return _password = value;
        },
        onEditingComplete: validateAndSubmit,
      ), //TextFormField

      SizedBox(height: 20.0),
    ];
  }

  List<Widget> createButtons() {
    if (_formType == FormType.login) {
      return[
        new RaisedButton(
          child: new Text("Login", style: new TextStyle(fontSize: 24.0)),
          textColor: Colors.white,
          color: Colors.indigo,

          onPressed: validateAndSubmit,
        ), //RaisedButton
        new FlatButton(
          child: new Text("Create Account", style: new TextStyle(fontSize: 20.0)),
          textColor: Colors.indigo,

          onPressed: moveToRegister,
        ), //FlatButton
      ];
    }
    else {
      return[
        new RaisedButton(
          child: new Text("Sign Up", style: new TextStyle(fontSize: 24.0)),
          textColor: Colors.white,
          color: Colors.indigo,

          onPressed: validateAndSubmit,
        ), //RaisedButton
        new FlatButton(
          child: new Text("Already have an account?", style: new TextStyle(fontSize: 20.0)),
          textColor: Colors.indigo,

          onPressed: moveToLogin,
        ), //FlatButton
      ];
    }
  }

  Widget logo() {
    return new Center(
      //tag: 'hero',

      child: new CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 100.0,
        child: Image.asset('images/logo.png', fit: BoxFit.cover),
      ),
    );
  }
}
