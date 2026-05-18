import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ota_update/ota_update.dart';

class UpdateService {
  /// Checks if an update is available and shows a dialog if it is.
  static Future<void> checkUpdate(BuildContext context) async {
    // Only run on Android as OTA update is for APKs
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      // 1. Get Current Version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      int currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;

      // 2. Fetch Version from Firestore
      // Required Firestore Document: collection('config').doc('app_update')
      DocumentSnapshot updateDoc = await FirebaseFirestore.instance
          .collection('config')
          .doc('app_update')
          .get();

      if (!updateDoc.exists) return;

      Map<String, dynamic> data = updateDoc.data() as Map<String, dynamic>;
      int latestVersionCode = data['latest_version_code'] ?? 0;
      String updateUrl = data['update_url'] ?? '';
      bool isForceUpdate = data['force_update'] ?? false;
      String message = data['message'] ?? 'A new version of the app is available. Please update to continue.';

      // 3. Compare versions
      debugPrint("Current Version: $currentVersionCode, Latest: $latestVersionCode");

      if (latestVersionCode > currentVersionCode) {
        if (!context.mounted) return;
        _showUpdateDialog(context, updateUrl, isForceUpdate, message);
      }
    } catch (e) {
      debugPrint("Update Check Error: $e");
    }
  }

  static void _showUpdateDialog(BuildContext context, String url, bool force, String msg) {
    showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (context) => PopScope(
        canPop: !force,
        child: _UpdatePopup(url: url, force: force, message: msg),
      ),
    );
  }
}

class _UpdatePopup extends StatefulWidget {
  final String url;
  final bool force;
  final String message;

  const _UpdatePopup({
    required this.url,
    required this.force,
    required this.message,
  });

  @override
  State<_UpdatePopup> createState() => _UpdatePopupState();
}

class _UpdatePopupState extends State<_UpdatePopup> {
  OtaEvent? currentEvent;
  bool isUpdating = false;

  Future<void> startUpdate() async {
    setState(() {
      isUpdating = true;
    });

    try {
      // OtaUpdate().execute starts the download and triggers the installation
      OtaUpdate().execute(
        widget.url,
        destinationFilename: 'update.apk',
        androidProviderAuthority: 'com.example.my_flutter_webside.ota_update_provider',
      ).listen(
        (event) {
          setState(() {
            currentEvent = event;
          });
          if (event.status == OtaStatus.INSTALLING) {
            debugPrint("Update status: Ready to install");
          }
        },
        onError: (e) {
          debugPrint('OTA update error: $e');
          setState(() {
            isUpdating = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Update failed: $e')),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('Failed to start update: $e');
      setState(() {
        isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = 0;
    if (currentEvent?.value != null) {
      progress = (double.tryParse(currentEvent!.value!) ?? 0) / 100;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Row(
        children: [
          Icon(Icons.system_update, color: Color(0xFFC5A059)),
          SizedBox(width: 10),
          Text("Update Available"),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          if (isUpdating) ...[
            const SizedBox(height: 25),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              color: const Color(0xFFC5A059),
              minHeight: 8,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _getStatusText(currentEvent?.status, currentEvent?.value),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!widget.force && !isUpdating)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Later", style: TextStyle(color: Colors.grey)),
          ),
        if (!isUpdating)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC5A059),
              foregroundColor: Colors.white,
            ),
            onPressed: startUpdate,
            child: const Text("Update Now"),
          ),
      ],
    );
  }

  String _getStatusText(OtaStatus? status, String? value) {
    switch (status) {
      case OtaStatus.DOWNLOADING:
        return "Downloading: $value%";
      case OtaStatus.INSTALLING:
        return "Installing... Please wait";
      case OtaStatus.ALREADY_RUNNING_ERROR:
        return "An update is already in progress";
      case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
        return "Permission denied to install update";
      case OtaStatus.INTERNAL_ERROR:
        return "An internal error occurred";
      case OtaStatus.DOWNLOAD_ERROR:
        return "Download failed. Check your internet.";
      case OtaStatus.CHECKSUM_ERROR:
        return "Update file is corrupted";
      default:
        return "Preparing update...";
    }
  }
}
