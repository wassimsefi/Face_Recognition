import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:faceTest/pages/db/database.dart';
import 'package:faceTest/pages/models/user.model.dart';
import 'package:faceTest/pages/profile.dart';
import 'package:faceTest/pages/widgets/app_button.dart';
import 'package:faceTest/services/camera.service.dart';
import 'package:faceTest/services/facenet.service.dart';
import 'package:flutter/material.dart';
import '../home.dart';
import 'package:http/http.dart' as http;
import 'app_text_field.dart';

class AuthActionButton extends StatefulWidget {
  AuthActionButton(this._initializeControllerFuture,
      {Key key, @required this.onPressed, @required this.isLogin, this.reload});
  final Future _initializeControllerFuture;
  final Function onPressed;
  final bool isLogin;
  final Function reload;
  @override
  _AuthActionButtonState createState() => _AuthActionButtonState();
}

class _AuthActionButtonState extends State<AuthActionButton> {
  /// service injection
  final FaceNetService _faceNetService = FaceNetService();
  final DataBaseService _dataBaseService = DataBaseService();
  final CameraService _cameraService = CameraService();

  final TextEditingController _userTextEditingController =
      TextEditingController(text: '');
  final TextEditingController _passwordTextEditingController =
      TextEditingController(text: '');

  User predictedUser;

  /*Future<User> createUser(String user, String password, String p) async {
    final String apiUrl = "http://localhost:3000/api/userModel/signup";
    final Response = await http.post(apiUrl,
        body: {"firstName": user, "password": password, "image": p});

    if (Response.statusCode == 201) {
      print("success create user !!");
    } else {
      print("error create user !!");
      return null;
    }
  }
*/
  Future<User> createUser(String user, String password, List<dynamic> p) async {
    final response = await http.post(
      Uri.parse('https://mighty-shelf-59772.herokuapp.com/signup'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        "userName": user,
        "password": password,
        "image": p
      }),
    );

    if (response.statusCode == 201) {
      // If the server did return a 201 CREATED response,
      // then parse the JSON.
      print("success create user !!");
    } else {
      // If the server did not return a 201 CREATED response,
      // then throw an exception.
      throw Exception('Failed to create user.');
    }
  }

  Future _signUp(context) async {
    /// gets predicted data from facenet service (user face detected)
    List predictedData = _faceNetService.predictedData;
    String user = _userTextEditingController.text;
    String password = _passwordTextEditingController.text;

    /// creates a new user in the 'database'
    await _dataBaseService.saveData(user, password, predictedData);
    await createUser(user, password, predictedData);

    print("**********************Users/Sign UP****************************");

    print("name :" + user);
    print("password :" + password);
    print("image :" + predictedData.toString());

    print("************************end****************************");

    print("***** imagee ** image *****" + predictedData.toString());
    //   print("***** user ** user *****" + user.toString());

    /// resets the face stored in the face net sevice
    this._faceNetService.setPredictedData(null);
    Navigator.push(context,
        MaterialPageRoute(builder: (BuildContext context) => MyHomePage()));
  }

  Future _signIn(context, User predictedUser) async {
    String password = _passwordTextEditingController.text;
    Map<String, dynamic> data = _dataBaseService.db;

    print("**********************Users/login****************************");

    print("name :" + this.predictedUser.user);
    print(
        "image :" + data[this.predictedUser.user + ":" + password].toString());

    print("************************end****************************");

    if (this.predictedUser.password == password) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => Profile(
                    this.predictedUser.user,
                    imagePath: _cameraService.imagePath,
                  )));
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text('Wrong password!'),
          );
        },
      );
    }
  }

  String _predictUser() {
    String userAndPass = _faceNetService.predict();

    return userAndPass ?? null;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        try {
          // Ensure that the camera is initialized.
          await widget._initializeControllerFuture;
          // onShot event (takes the image and predict output)
          bool faceDetected = await widget.onPressed();
          if (faceDetected) {
            if (widget.isLogin) {
              var userAndPass = _predictUser();
              if (userAndPass != null) {
                this.predictedUser = User.fromDB(userAndPass);
              }
            }
            PersistentBottomSheetController bottomSheetController =
                Scaffold.of(context).showBottomSheet((context) =>
                    widget.isLogin ? signSheet(context) : signSheetUp(context));

            bottomSheetController.closed.whenComplete(() => widget.reload());
          }
        } catch (e) {
          // If an error occurs, log the error to the console.
          print(e);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Color(0xFF0F0BDB),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        width: MediaQuery.of(context).size.width * 0.8,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'CAPTURE',
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(
              width: 10,
            ),
            Icon(Icons.camera_alt, color: Colors.white)
          ],
        ),
      ),
    );
  }

  signSheet(context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          widget.isLogin && predictedUser != null
              ? Container(
                  child: Text(
                    'Welcome back , ' + predictedUser.user + '.',
                    style: TextStyle(fontSize: 20),
                  ),
                )
              : widget.isLogin
                  ? Container(
                      child: Text(
                      'User not found 😞',
                      style: TextStyle(fontSize: 20),
                    ))
                  : Container(),
          Container(
            child: Column(
              children: [
                !widget.isLogin
                    ? AppTextField(
                        controller: _userTextEditingController,
                        labelText: "Your Name",
                      )
                    : Container(),
                SizedBox(height: 10),
                widget.isLogin && predictedUser == null
                    ? Container()
                    : AppTextField(
                        controller: _passwordTextEditingController,
                        labelText: "Password",
                        isPassword: true,
                      ),
                SizedBox(height: 10),
                Divider(),
                SizedBox(height: 10),
                widget.isLogin && predictedUser != null
                    ? AppButton(
                        text: 'LOGIN',
                        onPressed: () async {
                          _signIn(context, predictedUser);
                        },
                        icon: Icon(
                          Icons.login,
                          color: Colors.white,
                        ),
                      )
                    : !widget.isLogin
                        ? AppButton(
                            text: 'SIGN UP',
                            onPressed: () async {
                              await _signUp(context);
                            },
                            icon: Icon(
                              Icons.person_add,
                              color: Colors.white,
                            ),
                          )
                        : Container(),
              ],
            ),
          )
        ],
      ),
    );
  }

  signSheetUp(context) {
    var userAndPass = _predictUser();
    if (userAndPass != null) {
      this.predictedUser = User.fromDB(userAndPass);
    }
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          predictedUser == null
              ? Container(
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _userTextEditingController,
                        labelText: "Your Name",
                      ),
                      SizedBox(height: 10),
                      AppTextField(
                        controller: _passwordTextEditingController,
                        labelText: "Password",
                        isPassword: true,
                      ),
                      SizedBox(height: 10),
                      Divider(),
                      SizedBox(height: 10),
                      AppButton(
                        text: 'SIGN UP',
                        onPressed: () async {
                          await _signUp(context);
                        },
                        icon: Icon(
                          Icons.person_add,
                          color: Colors.white,
                        ),
                      )
                    ],
                  ),
                )
              : Container(
                  alignment: Alignment.center,
                  width: MediaQuery.of(context).size.width,
                  child: Text(
                    'User existe 😞 :' + this.predictedUser.user,
                    style: TextStyle(fontSize: 20),
                  )),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
