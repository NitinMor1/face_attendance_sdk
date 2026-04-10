import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class ToolkitStore extends ChangeNotifier {
  static const String _identitiesKey = 'face_kit_identities';
  static const String _eventsKey = 'face_kit_events';

  List<SDKIdentity> _identities = [];
  List<RecognitionEvent> _events = [];

  List<SDKIdentity> get identities => _identities;
  List<RecognitionEvent> get events => _events;

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Identities
    final idJson = prefs.getStringList(_identitiesKey) ?? [];
    _identities = idJson
        .map((s) => SDKIdentity.fromJson(jsonDecode(s)))
        .toList();

    // Load Events
    final eventJson = prefs.getStringList(_eventsKey) ?? [];
    _events = eventJson
        .map((s) => RecognitionEvent.fromJson(jsonDecode(s)))
        .toList();

    notifyListeners();
  }

  IdentityCategory? _activeCategoryFilter;
  IdentityCategory? get activeCategoryFilter => _activeCategoryFilter;

  void setCategoryFilter(IdentityCategory? category) {
    _activeCategoryFilter = category;
    notifyListeners();
  }

  Future<void> addIdentity(SDKIdentity identity) async {
    _identities.add(identity);
    await _saveIdentities();
    
    // Log enrollment event
    await logEvent(RecognitionEvent(
      identityId: identity.id,
      identityName: identity.name,
      category: identity.category,
      timestamp: DateTime.now(),
      type: EventType.enrollment,
    ));

    notifyListeners();
  }

  Future<void> logEvent(RecognitionEvent event) async {
    _events.add(event);
    await _saveEvents();
    notifyListeners();
  }

  Future<void> _saveIdentities() async {
    final prefs = await SharedPreferences.getInstance();
    final json = _identities.map((i) => jsonEncode(i.toJson())).toList();
    await prefs.setStringList(_identitiesKey, json);
  }

  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final json = _events.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_eventsKey, json);
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_identitiesKey);
    await prefs.remove(_eventsKey);
    _identities = [];
    _events = [];
    notifyListeners();
  }
}
