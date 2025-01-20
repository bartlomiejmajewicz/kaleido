import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:io' show Platform;


abstract class UniqueDeviceId {


  static Future<String> getDeviceUuid() async {
    WidgetsFlutterBinding.ensureInitialized();
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceIdentifier;

    if (Platform.isAndroid) {
      // Android: Pobieranie androidId
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceIdentifier = androidInfo.serialNumber ?? 'unknown';
    } else if (Platform.isIOS) {
      // iOS: Pobieranie identifierForVendor
      final iosInfo = await deviceInfo.iosInfo;
      deviceIdentifier = iosInfo.identifierForVendor ?? 'unknown';
    } else if (Platform.isWindows) {
      // Windows: Pobieranie deviceId
      final windowsInfo = await deviceInfo.windowsInfo;
      deviceIdentifier = windowsInfo.deviceId ?? 'unknown';
    } else if (Platform.isMacOS) {
      // macOS: Pobieranie systemGUID
      final macosInfo = await deviceInfo.macOsInfo;
      deviceIdentifier = macosInfo.systemGUID ?? 'unknown';
    } else if (Platform.isLinux) {
      // Linux: Pobieranie machineId
      final linuxInfo = await deviceInfo.linuxInfo;
      deviceIdentifier = linuxInfo.machineId ?? 'unknown';
    } else {
      // Dla innych platform zwracamy 'unknown'
      deviceIdentifier = 'unknown_platform';
    }

    const uuid = Uuid();
    const namespace = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';
    final deviceUuid = uuid.v5(namespace, deviceIdentifier);

    return deviceUuid;
  }


}