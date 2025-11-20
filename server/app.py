from flask import Flask, request, jsonify
from PIL import Image, ImageDraw
import io
import base64

import uuid
from datetime import datetime
from flask_cors import CORS
import sqlite3
from os import path

import database
from process_image import process_image

app = Flask(__name__)
CORS(app)


@app.route('/upload', methods=['POST'])
def upload_image():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400

    file = request.files['file']
    session_id = request.form.get('session_id', str(uuid.uuid4()))

    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    try:
        # Читаем и обрабатываем изображение
        image = Image.open(file.stream).convert("RGB")
        processed_image, number, text = process_image(image)

        # Сохраняем в БД
        drawing_id = database.save_drawing_to_db(
            session_id=session_id,
            filename=file.filename,
            processed_image=processed_image,
            check_result=text
        )

        # Конвертируем для ответа
        buffered = io.BytesIO()
        processed_image.save(buffered, format="PNG")
        img_str = base64.b64encode(buffered.getvalue()).decode('utf-8')

        return jsonify({
            'success': True,
            'image_base64': img_str,
            'text': text,
            'drawing_id': drawing_id,
            'session_id': session_id,
            'number': number
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/history/<session_id>', methods=['GET'])
def get_history(session_id):
    try:
        drawings = database.get_history(session_id)

        # Конвертируем в словари
        result = []
        for row in drawings:
            result.append({
                'id': row[0],
                'filename': row[1],
                'status': row[2],
                'check_result': row[3],
                'created_at': row[4]
            })

        return jsonify({'drawings': result})
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/drawing/<int:drawing_id>', methods=['GET'])
def get_drawing(drawing_id):
    try:
        row = database.get_drawing(drawing_id)
        if row:
            # Конвертируем bytes в base64
            img_str = base64.b64encode(row[0]).decode('utf-8') if row[0] else None
            return jsonify({
                'image_base64': img_str,
                'filename': row[1],
                'check_result': row[2],
                'status': row[3]
            })
        else:
            return jsonify({'error': 'Drawing not found'}), 404

    except Exception as e:
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    # Создаем БД если нет
    if not path.exists('drawings.db'):
        database.create_db()

    app.run(host='0.0.0.0', port=5000, debug=True)
