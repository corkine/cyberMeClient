import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pocket/config.dart';

part 'track.g.dart';
part 'track.freezed.dart';

@freezed
class TrackSearchItem with _$TrackSearchItem {
  const factory TrackSearchItem(
      {required String title,
      required String search,
      required String id}) = _TrackSearchItem;
  factory TrackSearchItem.fromJson(Map<String, dynamic> json) =>
      _$TrackSearchItemFromJson(json);
}

@Freezed(makeCollectionsUnmodifiable: false)
class TrackSetting with _$TrackSetting {
  const factory TrackSetting(
      {@Default(true) bool sortByName,
      @Default("") String lastSearch,
      @Default([]) List<TrackSearchItem> searchItems}) = _TrackSetting;
  factory TrackSetting.fromJson(Map<String, dynamic> json) =>
      _$TrackSettingFromJson(json);
}

@riverpod
class TrackSettings extends _$TrackSettings {
  @override
  Future<TrackSetting> build() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString('trackSetting');
    try {
      if (jsonData != null) {
        final data = TrackSetting.fromJson(jsonDecode(jsonData));
        return data;
      }
    } catch (e) {
      debugPrintStack(stackTrace: StackTrace.current, label: e.toString());
    }
    return const TrackSetting();
  }

  setTrack(List<TrackSearchItem>? items) async {
    final prefs = await SharedPreferences.getInstance();
    final sort = state.value?.sortByName ?? true;
    final data = TrackSetting(sortByName: sort, searchItems: items ?? []);
    await prefs.setString('trackSetting', jsonEncode(data.toJson()));
    state = AsyncData(data);
  }

  setTrackSortReversed() async {
    final prefs = await SharedPreferences.getInstance();
    final sort = state.value?.sortByName ?? true;
    final items = state.value?.searchItems;
    final data = TrackSetting(sortByName: !sort, searchItems: items ?? []);
    await prefs.setString('trackSetting', jsonEncode(data.toJson()));
    state = AsyncData(data);
  }

  addTrack(TrackSearchItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final sort = state.value?.sortByName ?? true;
    final items = state.value?.searchItems;
    final data = TrackSetting(
        sortByName: sort,
        searchItems: {...items ?? <TrackSearchItem>[], item}.toList());
    await prefs.setString('trackSetting', jsonEncode(data.toJson()));
    state = AsyncData(data);
  }

  setLastSearch(String lastSearch) async {
    final prefs = await SharedPreferences.getInstance();
    final t = state.value;
    if (t == null) return;
    final data = t.copyWith(lastSearch: lastSearch);
    await prefs.setString('trackSetting', jsonEncode(data.toJson()));
    state = AsyncData(data);
  }
}

@riverpod
Future<List<(String, String)>> fetchTrack(FetchTrackRef ref) async {
  final setting = ref.watch(trackSettingsProvider).value;
  if (setting == null) return [];
  final Response r =
      await get(Uri.parse(Config.visitsUrl), headers: config.cyberBase64Header);
  final d = jsonDecode(r.body);
  if ((d["status"] as int?) == 1) {
    final res = (d["data"] as List)
        .map((e) => e as List)
        .map((e) => (e.first.toString(), e.last.toString()))
        .toList(growable: false);
    return res;
  } else {
    return [];
  }
}

@riverpod
List<(String, String)> trackData(TrackDataRef ref, String searchText) {
  final setting = ref.watch(trackSettingsProvider).value;
  final data = ref.watch(fetchTrackProvider).value;
  if (setting == null || data == null) return [];
  var res = data;
  if (setting.sortByName) {
    res.sort((a, b) {
      return a.$1.compareTo(b.$1);
    });
  } else {
    res.sort((a, b) {
      return int.parse(b.$2).compareTo(int.parse(a.$2));
    });
  }
  if (searchText.isNotEmpty) {
    res = res.where((e) {
      return e.$1.contains(searchText);
    }).toList(growable: false);
  }
  return res;
}