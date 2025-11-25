import 'dart:io';
import 'dart:typed_data';

import 'package:GOSTGuard/features/checking_drawing/image_select_card.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../common/services/upload_service.dart';
import '../../common/widgets/alert.dart';
import '../../common/widgets/base_screen.dart';
import '../../common/widgets/primary_button.dart';
import 'image_result_card.dart';

/// Экран загрузки изображения на сервер
class CheckingScreen extends StatefulWidget {
  const CheckingScreen({super.key});

  @override
  State<CheckingScreen> createState() => _CheckingScreenState();
}

class _CheckingScreenState extends State<CheckingScreen> {
  File? _image;
  Uint8List? _responseImage;
  String? _responseText;
  int? _responseNumber;
  bool _isUploading = false;

  final _uploader = UploadService();
  final picker = ImagePicker();

  /// Функция загрузки изображения на сервер
  Future<void> _uploadImage() async {
    if (_image == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // ВСЁ ТО ЖЕ САМОЕ, но теперь работает локально!
      final result = await _uploader.uploadImage(image: _image!);

      setState(() {
        _responseText = result.text;
        _responseNumber = result.number;
        _responseImage = result.image;
        _isUploading = false;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  /// Функция выбора изображения из галереи
  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 0, bottom: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //
            if (_isUploading)
              const Center(child: CircularProgressIndicator())
            // Если изображение ещё не обработано — карточка с выбором изображения
            else if (_responseImage == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Кнопка "Справка"
                  Align(
                    alignment: Alignment.topLeft,
                    child: PrimaryButton(
                      icon: Icons.help_outline,
                      label: 'Справка',
                      radius: 12,
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => Alert(
                            title: 'Пояснение',
                            message:
                                'Нажмите на кнопку "Добавить фото" и загрузите '
                                'фото чертежа, после нажмите на галочку '
                                'снизу.',
                            onOk: () => Navigator.pop(context),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  ImageSelectCard(image: _image, onPick: _pickImage),

                  // Галочка для отправки
                  PrimaryButton(
                    icon: Icons.check,
                    onPressed: () async {
                      await _uploadImage();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Проверка завершена ✅')),
                      );
                    },
                  ),
                ],
              )
            // Если изображение обработано — показываем результат
            else
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        // Возвращение к выбору изображения
                        PrimaryButton(
                          icon: Icons.arrow_back,
                          label: "Загрузить ещё",
                          radius: 12,
                          onPressed: () {
                            setState(() {
                              _responseImage = null;
                              _responseText = null;
                              _responseNumber = null;
                            });
                          },
                        ),

                        SizedBox(width: 10),

                        // Кнопка "Справка"
                        PrimaryButton(
                          icon: Icons.help_outline,
                          label: 'Справка',
                          radius: 12,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => Alert(
                                title: 'Пояснение',
                                message:
                                    'Цифрами на чертеже отмечены проблемные '
                                    'места, ниже указаны конкретные ГОСТы, которым '
                                    'они не соответствуют.',
                                onOk: () => Navigator.pop(context),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    ImageResultCard(
                      responseImage: _responseImage!,
                      number: _responseNumber!,
                      text: _responseText!,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
