import 'dart:convert';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/custom_exception.dart';

class Auth with ChangeNotifier {
  String _userId;
  String _email;
  String _condition;
  String _name;

  bool get isAuth {
    return _email != null;
  }

  String get userId {
    return _userId;
  }

  String get email {
    return _email;
  }

  String get condition {
    return _condition;
  }

  String get name {
    return _name;
  }

  Future<void> updateUserCount(String field) async {
    await Firebase.initializeApp();
    final email = _email;
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    return users.where('email', isEqualTo: email).get().then((value) {
      return value.docs.forEach((element) {
        return users
            .doc(element.id)
            .update({field: (int.parse(element[field]) + 1).toString()});
      });
    });
  }

  Future<void> updateUserLog(logs) async {
    await Firebase.initializeApp();
    final email = _email;
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    return users.where('email', isEqualTo: email).get().then((value) {
      value.docs.forEach((element) {
        users.doc(element.id).update({'log': FieldValue.arrayUnion(logs)});
      });
    });
  }

  Future<void> updaterestaurantsCount(String field, restaurantsId) async {
    await Firebase.initializeApp();
    CollectionReference restaurants =
        FirebaseFirestore.instance.collection('restaurants');
    return restaurants.doc(restaurantsId).get().then((value) {
      final resultData = Map<String, dynamic>.from(value.data());
      restaurants.doc(restaurantsId).update({field: resultData[field] + 1});
    });
  }

  Future<void> getUserData(String email) async {
    await Firebase.initializeApp();
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    return users.where("email", isEqualTo: email).get().then((querySnapshot) {
      querySnapshot.docs.forEach((element) {
        final resultData = Map<String, dynamic>.from(element.data());
        _userId = resultData['userId'];
        _condition = resultData['condition'];
        _name = resultData['name'];
      });
    });
  }

  Future<void> login(String email) async {
    await Firebase.initializeApp();
    Map<String, dynamic> resultData;
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    return users.where("email", isEqualTo: email).get().then((querySnapshot) {
      if (querySnapshot.docs.length == 0) {
        throw CustomException("Email錯誤!請重新輸入!");
      }
      querySnapshot.docs.forEach((result) async {
        resultData = Map<String, dynamic>.from(result.data());
        _email = resultData['email'];
        _userId = resultData['userId'];
        _condition = resultData['condition'];
        _name = resultData['name'];
        notifyListeners();
        final prefs = await SharedPreferences.getInstance();
        final userData = json.encode({
          'email': _email,
          'userId': _userId,
          'condition': _condition,
          'name': _name,
        });
        prefs.setString('userData', userData);
        print('conditoon: $_condition');
        print('email: $_email');
        print('name: $_name');
      });
    });
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return false;
    }
    final extractedUserData =
        json.decode(prefs.getString('userData')) as Map<String, Object>;
    _email = extractedUserData['email'];
    _userId = extractedUserData['userId'];
    _condition = extractedUserData['condition'];
    _name = extractedUserData['name'];
    if (_email == null) {
      return false;
    }
    notifyListeners();
    try {
      getUserData(email).whenComplete(() {
        print('extractedUserData: $extractedUserData');
      });
    } catch (e) {
      return false;
    }
    return true;
  }

  void logout() {
    _email = null;
    _condition = null;
    _name = null;
    _userId = null;
    notifyListeners();
  }
}
