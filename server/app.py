from flask import Flask, request, jsonify
import io
import uuid
from flask_cors import CORS
from process_image import process_image, get_image_from_request, create_final_image_with_all_annotations
from process_arrow_heads import process_arrow_heads
from process_arrow_distances import process_arrow_distances
from process_text import process_text
import base64
from ultralytics import YOLO

from server.generate_report import generate_word_report

app = Flask(__name__)
CORS(app)

model = YOLO("best.pt")
model2 = YOLO("best.pt")

@app.route('/upload', methods=['POST'])
def upload_image():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400

    file = request.files['file']
    session_id = request.form.get('session_id', str(uuid.uuid4()))

    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    try:
        # Читаем изображение один раз
        original_image, image_np, file_stream = get_image_from_request(file)

        # 1. ПРОВЕРКА РАМКИ
        processed_image, frame_text = process_image(original_image, model2)

        # 2. ПРОВЕРКА НАКОНЕЧНИКОВ СТРЕЛОК
        arrow_heads_violations, arrow_heads_stats, arrow_heads_text, _ = process_arrow_heads(image_np, model)

        # 3. ПРОВЕРКА РАССТОЯНИЙ
        arrow_distances_violations, arrow_distances_stats, arrow_distances_text, _ = process_arrow_distances(image_np,
                                                                                                             model)

        # 4. ПРОВЕРКА ТЕКСТА
        text_violations, text_warnings, text_stats, text_text, _ = process_text(image_np, model)

        # финальное изображение все со всем
        final_image = create_final_image_with_all_annotations(
            original_image=original_image,
            processed_image=processed_image,
            arrow_heads_violations_data=arrow_heads_violations,
            arrow_distances_violations_data=arrow_distances_violations,
            text_violations_data=text_violations,
            model=model
        )

        # ОБЪЕДИНЯЕМ ВСЕ РЕЗУЛЬТАТЫ
        all_violations = (arrow_heads_violations + arrow_distances_violations + text_violations)

        # Формируем общий текст результата
        combined_text = f"""📐 ПРОВЕРКА РАМКИ:
{frame_text}

🎯 ПРОВЕРКА НАКОНЕЧНИКОВ СТРЕЛОК (ГОСТ 2.307-68):
{arrow_heads_text}

📏 ПРОВЕРКА РАССТОЯНИЙ (ГОСТ 2.307-68):
{arrow_distances_text}

📝 ПРОВЕРКА ТЕКСТА (ГОСТ 2.304-81):
{text_text}"""

        # Конвертируем финальное изображение
        buffered = io.BytesIO()
        final_image.save(buffered, format="PNG")
        img_str = base64.b64encode(buffered.getvalue()).decode('utf-8')

        return jsonify({
            'success': True,
            'image_base64': img_str,
            'text': combined_text,
            'session_id': session_id,
            'full_report': {
                'frame_check': {
                    'result': frame_text,
                },
                'arrow_heads_check': {
                    'result': arrow_heads_text,
                    'violations': arrow_heads_violations,
                    'statistics': arrow_heads_stats,
                    'gost_standard': 'ГОСТ 2.307-68'
                },
                'arrow_distances_check': {
                    'result': arrow_distances_text,
                    'violations': arrow_distances_violations,
                    'statistics': arrow_distances_stats,
                    'gost_standard': 'ГОСТ 2.307-68'
                },
                'text_check': {
                    'result': text_text,
                    'violations': text_violations,
                    'warnings': text_warnings,
                    'statistics': text_stats,
                    'gost_standard': 'ГОСТ 2.304-81'
                },
                'summary': {
                    'total_violations': len(all_violations),
                    'has_violations': len(all_violations) > 0
                }
            }
        })

    except Exception as e:
        print(f"Ошибка в /upload: {str(e)}")
        import traceback
        print(f"Трассировка: {traceback.format_exc()}")
        return jsonify({'error': str(e)}), 500


@app.route('/generate_report', methods=['POST'])
def generate_report():
    try:
        data = request.get_json()

        drawing_id = data.get('drawing_id')
        filename = data.get('filename')
        check_result = data.get('check_result')
        image_base64 = data.get('image_base64')
        created_at = data.get('created_at')

        if not all([drawing_id, filename, check_result, image_base64]):
            return jsonify({'error': 'Missing required data'}), 400

        # Генерируем Word отчет
        doc_buffer = generate_word_report(
            drawing_id=drawing_id,
            filename=filename,
            check_result=check_result,
            image_base64=image_base64,
            created_at=created_at
        )

        # Кодируем Word в base64 для отправки
        doc_base64 = base64.b64encode(doc_buffer.getvalue()).decode('utf-8')

        return jsonify({
            'success': True,
            'doc_base64': doc_base64,
            'filename': f'report_{drawing_id}.docx'
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500



if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)