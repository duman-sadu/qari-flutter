import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';
import '../services/friend_service.dart';

class OnboardingProvider extends ChangeNotifier {
  String firstName = '';
  String lastName = '';
  String middleName = '';
  String? gender;
  String age = '';
  bool knowsTajweed = false;
  List<int> knownSurahs = [];

  Future<void> setAll({
    required String first,
    required String last,
    required String middle,
    required String g,
    required String a,
    required bool tajweed,
    required List<int> known,
  }) async {
    firstName = first;
    lastName = last;
    middleName = middle;
    gender = g;
    age = a;
    knowsTajweed = tajweed;
    knownSurahs = known;
    notifyListeners();

    await _saveProfileLocal();

    try {
      await FirestoreService.saveProfile({
        'firstName': first,
        'lastName': last,
        'middleName': middle,
        'gender': g,
        'age': a,
        'knowsTajweed': tajweed,
        'knownSurahs': known,
      });
      FriendService.publishMyStats(
        name: [last, first].where((s) => s.isNotEmpty).join(' '),
      );
    } catch (_) {}
  }

  void updateProfile({
    String? first,
    String? last,
    String? middle,
    String? g,
    String? a,
    bool? tajweed,
    List<int>? known,
  }) {
    if (first != null) firstName = first;
    if (last != null) lastName = last;
    if (middle != null) middleName = middle;
    if (g != null) gender = g;
    if (a != null) age = a;
    if (tajweed != null) knowsTajweed = tajweed;
    if (known != null) knownSurahs = known;
    notifyListeners();

    _saveProfileLocal();
    FirestoreService.saveProfile({
      'firstName': firstName,
      'lastName': lastName,
      'middleName': middleName,
      'gender': gender ?? '',
      'age': age,
      'knowsTajweed': knowsTajweed,
      'knownSurahs': knownSurahs,
    });
    FriendService.publishMyStats(
      name: [lastName, firstName].where((s) => s.isNotEmpty).join(' '),
    );
  }

  Future<void> _saveProfileLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('firstName', firstName);
    await prefs.setString('lastName', lastName);
    await prefs.setString('middleName', middleName);
    if (gender != null) await prefs.setString('gender', gender!);
    await prefs.setString('age', age);
    await prefs.setBool('knowsTajweed', knowsTajweed);
    await prefs.setString('knownSurahs', jsonEncode(knownSurahs));
  }

  /// Load profile from local storage (called on app start).
  Future<void> loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    firstName = prefs.getString('firstName') ?? '';
    lastName = prefs.getString('lastName') ?? '';
    middleName = prefs.getString('middleName') ?? '';
    gender = prefs.getString('gender');
    age = prefs.getString('age') ?? '';
    knowsTajweed = prefs.getBool('knowsTajweed') ?? false;

    final surahsJson = prefs.getString('knownSurahs');
    if (surahsJson != null) {
      knownSurahs = List<int>.from(jsonDecode(surahsJson));
    }

    notifyListeners();
  }

  /// Fetch profile from Firestore and update local state (called after login).
  Future<void> loadFromFirestore() async {
    final data = await FirestoreService.loadProfile();
    if (data == null) return;

    firstName = data['firstName']?.toString() ?? firstName;
    lastName = data['lastName']?.toString() ?? lastName;
    middleName = data['middleName']?.toString() ?? middleName;
    gender = data['gender']?.toString() ?? gender;
    age = data['age']?.toString() ?? age;
    knowsTajweed = data['knowsTajweed'] as bool? ?? knowsTajweed;

    final remoteKnown = data['knownSurahs'];
    if (remoteKnown is List) {
      knownSurahs = remoteKnown.map((e) => (e as num).toInt()).toList();
    }

    notifyListeners();
    await _saveProfileLocal();
  }
}
