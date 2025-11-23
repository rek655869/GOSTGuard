import 'package:flutter/material.dart';
import '../common/services/drawing_service.dart';
import '../common/services/upload_service.dart';
import '../common/widgets/prompt.dart';
import 'navigation.dart';

class IpEntryWrapper extends StatefulWidget {
  const IpEntryWrapper({super.key});

  @override
  State<IpEntryWrapper> createState() => _IpEntryWrapperState();
}

class _IpEntryWrapperState extends State<IpEntryWrapper> {
  String? _serverIp;
  bool _ipConfigured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _askForIp();
    });
  }

  Future<void> _askForIp() async {
    final controller = TextEditingController(text: _serverIp);

    String? ip = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Prompt(
        controller: controller,
        title: 'Введите IP сервера для обработки',
        labelText: 'IP адрес сервера',
        confirmText: 'Подключиться',
        onConfirm: (value) {
          if (value != null && value.isNotEmpty) {
            Navigator.of(context).pop(value);
          }
        },
      ),
    );

    if (ip != null && ip.isNotEmpty) {
      setState(() {
        _serverIp = ip;
        _setupServices(ip);
        _ipConfigured = true;
      });
    }
  }

  void _setupServices(String ip) {
    final url = "http://$ip:5000";
    DrawingService.setBaseUrl(url);
    UploadService.setUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ipConfigured) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Navigation();
  }
}