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

  @override
  void initState() {
    super.initState();
    // Запускаем диалог после построения виджета
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _askForIp();
    });
  }

  Future<void> _askForIp() async {
    _serverIp = "10.13.176.229";

    final controller = TextEditingController(text: _serverIp);

    String? ip = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Prompt(
        controller: controller,
        title: 'Введите IP сервера',
        labelText: 'IP адрес',
        confirmText: 'Сохранить',
        onConfirm: (value) {
            Navigator.of(context).pop(value);
        },
      ),
    );

    setState(() {
      _serverIp = ip ?? _serverIp;
      DrawingService.setBaseUrl("http://${_serverIp}:5000");
      UploadService.setUrl("http://${_serverIp}:5000");
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_serverIp == null) {
      // Пока IP не введён, показываем индикатор загрузки
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Navigation();
  }
}