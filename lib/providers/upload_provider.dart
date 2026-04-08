import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/upload_history.dart';

class UploadProvider with ChangeNotifier {
  List<UploadHistoryItem> _history = [];
  bool _isLoading = false;

  List<UploadHistoryItem> get history => _history;
  bool get isLoading => _isLoading;

  UploadProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString('upload_history');
      if (historyJson != null) {
        final List<dynamic> historyList = jsonDecode(historyJson);
        _history =
            historyList.map((e) => UploadHistoryItem.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToHistory(UploadHistoryItem item) async {
    _history.insert(0, item);
    await _saveHistory();
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String historyJson = jsonEncode(
      _history.map((e) => e.toJson()).toList(),
    );
    await prefs.setString('upload_history', historyJson);
  }

  Future<void> clearHistory() async {
    _history.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('upload_history');
    notifyListeners();
  }
}
