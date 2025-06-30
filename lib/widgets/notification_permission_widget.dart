import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dealit_app/services/fcm_service.dart';

class NotificationPermissionWidget extends StatefulWidget {
  const NotificationPermissionWidget({super.key});

  @override
  State<NotificationPermissionWidget> createState() => _NotificationPermissionWidgetState();
}

class _NotificationPermissionWidgetState extends State<NotificationPermissionWidget> {
  bool _hasPermission = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    bool hasPermission = await FCMService().isNotificationPermissionGranted();
    setState(() {
      _hasPermission = hasPermission;
      _isLoading = false;
    });
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // FCM 서비스 재초기화 (권한 요청 포함)
      await FCMService().initialize();
      
      // 권한 상태 다시 확인
      await _checkPermission();
      
      if (_hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('알림이 활성화되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          _showPermissionDeniedDialog();
        }
      }
    } catch (e) {
      print('권한 요청 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('권한 요청 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('알림 권한 필요'),
          content: const Text(
            '핫딜 알림을 받으려면 알림 권한이 필요합니다.\n'
            '설정에서 알림을 허용해 주세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                FCMService().openNotificationSettings();
              },
              child: const Text('설정으로 이동'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasPermission) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.green[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '알림이 활성화되어 있습니다',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  const Text(
                    '핫딜 알림을 받을 수 있습니다',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_off, color: Colors.orange[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '알림 권한이 필요합니다',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '핫딜 알림을 받으려면 알림 권한을 허용해 주세요.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _requestPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('알림 허용'),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => FCMService().openNotificationSettings(),
                child: const Text('설정'),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 