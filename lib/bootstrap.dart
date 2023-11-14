import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hiddify/core/app/app_view.dart';
import 'package:hiddify/core/core_providers.dart';
import 'package:hiddify/core/prefs/prefs.dart';
import 'package:hiddify/data/data_providers.dart';
import 'package:hiddify/data/repository/app_repository_impl.dart';
import 'package:hiddify/domain/environment.dart';
import 'package:hiddify/features/common/active_profile/active_profile_notifier.dart';
import 'package:hiddify/features/common/window/window_controller.dart';
import 'package:hiddify/features/system_tray/system_tray_controller.dart';
import 'package:hiddify/services/auto_start_service.dart';
import 'package:hiddify/services/deep_link_service.dart';
import 'package:hiddify/services/service_providers.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:loggy/loggy.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

final _logger = Loggy('bootstrap');
const _testCrashReport = false;
final _loggers = MultiLogPrinter(const PrettyPrinter(), []);

Future<void> lazyBootstrap(
  WidgetsBinding widgetsBinding,
  Environment env,
) async {
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  if (PlatformUtils.isDesktop) await windowManager.ensureInitialized();

  final sentryLogger = SentryLoggyIntegration();
  _loggers.addPrinter(sentryLogger);
  Loggy.initLoggy();

  final appInfo = await AppRepositoryImpl.getAppInfo(env);
  final sharedPreferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      appInfoProvider.overrideWithValue(appInfo),
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
    ],
  );

  final enableAnalytics = container.read(enableAnalyticsProvider);

  await SentryFlutter.init(
    (options) {
      if ((enableAnalytics && !kDebugMode) || _testCrashReport) {
        options.dsn = Environment.sentryDSN;
      } else {
        options.dsn = "";
      }

      options.environment = env.name;
      options.dist = appInfo.release.name;
      options.debug = kDebugMode;
      options.enableNativeCrashHandling = true;
      options.enableNdkScopeSync = true;
      options.attachThreads = true;
      options.tracesSampleRate = 0.25;
      options.enableUserInteractionTracing = true;
      options.addIntegration(sentryLogger);
      options.beforeSend = sentryBeforeSend;
      options.logger = (level, message, {exception, logger, stackTrace}) {
        if (level == SentryLevel.fatal) {
          _logger.debug(message);
        }
      };
    },
    appRunner: () => _lazyBootstrap(widgetsBinding, container, env),
  );
}

Future<void> _lazyBootstrap(
  WidgetsBinding widgetsBinding,
  ProviderContainer container,
  Environment env,
) async {
  final debug = container.read(debugModeNotifierProvider) || kDebugMode;

  final filesEditor = container.read(filesEditorServiceProvider);
  await filesEditor.init();

  initLoggers(container.read, debug);
  _logger.info(container.read(appInfoProvider).format());

  final silentStart = container.read(silentStartNotifierProvider);
  if (silentStart) {
    FlutterNativeSplash.remove();
  }

  if (PlatformUtils.isDesktop) {
    _logger.debug("initializing [Auto Start Service] and [Window Controller]");
    await container.read(autoStartServiceProvider.future);
    await container.read(windowControllerProvider.future);
  }

  await container.read(singboxServiceProvider).init();
  _logger.debug("initialized [Singbox Service]");

  await container.read(activeProfileProvider.future);
  await container.read(deepLinkServiceProvider.future);
  if (PlatformUtils.isDesktop) {
    try {
      await container
          .read(systemTrayControllerProvider.future)
          .timeout(const Duration(seconds: 1));
      _logger.debug("initialized [System Tray Controller]");
    } catch (error, stackTrace) {
      _logger.warning(
        "error initializing [System Tray Controller]",
        error,
        stackTrace,
      );
    }
  }

  runApp(
    ProviderScope(
      parent: container,
      child: SentryUserInteractionWidget(
        child: const AppView(),
      ),
    ),
  );

  if (!silentStart) FlutterNativeSplash.remove();
}

void initLoggers(
  Result Function<Result>(ProviderListenable<Result>) read,
  bool debug,
) {
  final logLevel = debug ? LogLevel.all : LogLevel.info;
  final logToFile = debug || (!Platform.isAndroid && !Platform.isIOS);
  if (logToFile) {
    _loggers.addPrinter(
      FileLogPrinter(read(filesEditorServiceProvider).appLogsFile.path),
    );
  }
  Loggy.initLoggy(
    logPrinter: _loggers,
    logOptions: LogOptions(logLevel),
  );
}
