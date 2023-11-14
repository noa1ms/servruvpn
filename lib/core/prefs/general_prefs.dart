import 'package:flutter/foundation.dart';
import 'package:hiddify/core/core_providers.dart';
import 'package:hiddify/data/data_providers.dart';
import 'package:hiddify/domain/environment.dart';
import 'package:hiddify/domain/singbox/singbox.dart';
import 'package:hiddify/utils/pref_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'general_prefs.g.dart';

bool _debugIntroPage = false;

@Riverpod(keepAlive: true)
class IntroCompleted extends _$IntroCompleted {
  late final _pref = Pref(
    ref.watch(sharedPreferencesProvider),
    "intro_completed",
    false,
  );

  @override
  bool build() {
    if (_debugIntroPage && kDebugMode) return false;
    return _pref.getValue();
  }

  Future<void> update(bool value) {
    state = value;
    return _pref.update(value);
  }
}

@Riverpod(keepAlive: true)
class RegionNotifier extends _$RegionNotifier {
  late final _pref = Pref(
    ref.watch(sharedPreferencesProvider),
    "region",
    Region.other,
    mapFrom: Region.values.byName,
    mapTo: (value) => value.name,
  );

  @override
  Region build() => _pref.getValue();

  Future<void> update(Region value) {
    state = value;
    return _pref.update(value);
  }
}

@Riverpod(keepAlive: true)
class SilentStartNotifier extends _$SilentStartNotifier {
  late final _pref =
      Pref(ref.watch(sharedPreferencesProvider), "silent_start", false);

  @override
  bool build() => _pref.getValue();

  Future<void> update(bool value) {
    state = value;
    return _pref.update(value);
  }
}

@Riverpod(keepAlive: true)
class EnableAnalytics extends _$EnableAnalytics {
  late final _pref = Pref(
    ref.watch(sharedPreferencesProvider),
    "enable_analytics",
    true,
  );

  @override
  bool build() => _pref.getValue();

  Future<void> update(bool value) {
    state = value;
    return _pref.update(value);
  }
}

@Riverpod(keepAlive: true)
class DisableMemoryLimit extends _$DisableMemoryLimit {
  late final _pref = Pref(
    ref.watch(sharedPreferencesProvider),
    "disable_memory_limit",
    false,
  );

  @override
  bool build() => _pref.getValue();

  Future<void> update(bool value) {
    state = value;
    return _pref.update(value);
  }
}

@Riverpod(keepAlive: true)
class DebugModeNotifier extends _$DebugModeNotifier {
  late final _pref = Pref(
    ref.watch(sharedPreferencesProvider),
    "debug_mode",
    ref.read(envProvider) == Environment.dev,
  );

  @override
  bool build() => _pref.getValue();

  Future<void> update(bool value) {
    state = value;
    return _pref.update(value);
  }
}

@Riverpod(keepAlive: true)
class PerAppProxyModeNotifier extends _$PerAppProxyModeNotifier {
  late final _pref = Pref(
    ref.watch(sharedPreferencesProvider),
    "per_app_proxy_mode",
    PerAppProxyMode.off,
    mapFrom: PerAppProxyMode.values.byName,
    mapTo: (value) => value.name,
  );

  @override
  PerAppProxyMode build() => _pref.getValue();

  Future<void> update(PerAppProxyMode value) {
    state = value;
    return _pref.update(value);
  }
}

@Riverpod(keepAlive: true)
class PerAppProxyList extends _$PerAppProxyList {
  late final _include = Pref(
    ref.watch(sharedPreferencesProvider),
    "per_app_proxy_include_list",
    <String>[],
  );

  late final _exclude = Pref(
    ref.watch(sharedPreferencesProvider),
    "per_app_proxy_exclude_list",
    <String>[],
  );

  @override
  List<String> build() =>
      ref.watch(perAppProxyModeNotifierProvider) == PerAppProxyMode.include
          ? _include.getValue()
          : _exclude.getValue();

  Future<void> update(List<String> value) {
    state = value;
    if (ref.read(perAppProxyModeNotifierProvider) == PerAppProxyMode.include) {
      return _include.update(value);
    }
    return _exclude.update(value);
  }
}

@riverpod
class MarkNewProfileActive extends _$MarkNewProfileActive {
  late final _pref = Pref(
    ref.watch(sharedPreferencesProvider),
    "mark_new_profile_active",
    true,
  );

  @override
  bool build() => _pref.getValue();

  Future<void> update(bool value) {
    state = value;
    return _pref.update(value);
  }
}
