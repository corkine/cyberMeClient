import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'movie.g.dart';
part 'movie.freezed.dart';

@freezed
class MovieSetting with _$MovieSetting {
  const factory MovieSetting({
    @Default({}) Set<String> watchedTv,
    @Default({}) Set<String> watchedMovie,
  }) = _MovieSetting;

  factory MovieSetting.fromJson(Map<String, dynamic> json) =>
      _$MovieSettingFromJson(json);
}

@riverpod
class MovieSettings extends _$MovieSettings {
  @override
  Future<MovieSetting> build() async {
    final s = await SharedPreferences.getInstance();
    final d = s.getString("movieSetting");
    if (d == null) return const MovieSetting();
    try {
      return MovieSetting.fromJson(jsonDecode(d));
    } catch (e, tx) {
      debugPrintStack(stackTrace: tx, label: e.toString());
      return const MovieSetting();
    }
  }

  makeWatched(bool isTv, String url, {bool reverse = false}) async {
    final s = await SharedPreferences.getInstance();
    var v = state.value;
    if (v == null) return;
    if (!reverse) {
      if (isTv) {
        v = v.copyWith(watchedTv: {url, ...v.watchedTv});
      } else {
        v = v.copyWith(watchedMovie: {url, ...v.watchedMovie});
      }
    } else {
      if (isTv) {
        v = v.copyWith(
            watchedTv: v.watchedTv.where((element) => element != url).toSet());
      } else {
        v = v.copyWith(
            watchedMovie:
                v.watchedMovie.where((element) => element != url).toSet());
      }
    }
    await s.setString("movieSetting", jsonEncode(v.toJson()));
    state = AsyncData(v);
  }
}