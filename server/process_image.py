from PIL import Image, ImageDraw
import numpy as np
import math
import io


def get_image_from_request(file):
    """Универсальная функция для получения изображения из запроса"""
    try:
        # Сохраняем файл в памяти для многократного использования
        file_bytes = file.read()
        file_stream = io.BytesIO(file_bytes)
        image = Image.open(file_stream).convert("RGB")
        image_np = np.array(image)
        return image, image_np, file_stream
    except Exception as e:
        raise Exception(f"Ошибка чтения изображения: {str(e)}")


def create_final_image_with_all_annotations(original_image, processed_image,
                                            arrow_heads_violations_data,
                                            arrow_distances_violations_data,
                                            text_violations_data, model):
    """
    Создает финальное изображение со всеми аннотациями разных типов
    """
    # Начинаем с оригинального изображения
    final_image = processed_image.copy()
    draw = ImageDraw.Draw(final_image)

    # Разные цвета для разных типов нарушений
    colors = {
        'arrow_heads': 'pink',
        'arrow_distances': 'blue',
        'text': 'green',
        'frame': 'orange'
    }

    # 1. Рисуем нарушения наконечников стрелок (красные прямоугольники)
    if arrow_heads_violations_data and len(arrow_heads_violations_data) > 0:
        results = model.predict(np.array(original_image), imgsz=640)
        boxes = results[0].boxes.xyxy.cpu().numpy()
        classes = results[0].boxes.cls.cpu().numpy()

        arrows = [box for box, cls in zip(boxes, classes) if cls == 0]

        for i, arrow in enumerate(arrows):
            draw.rectangle([arrow[0], arrow[1], arrow[2], arrow[3]],
                           outline=colors['arrow_heads'], width=3)
            # Подпись для наконечника
            draw.text((arrow[0], arrow[1] - 20), f"Strelka {i + 1}",
                      fill=colors['arrow_heads'])

    # 2. Рисуем нарушения расстояний (синие линии)
    if arrow_distances_violations_data and len(arrow_distances_violations_data) > 0:
        results = model.predict(np.array(original_image), imgsz=640)
        boxes = results[0].boxes.xyxy.cpu().numpy()
        classes = results[0].boxes.cls.cpu().numpy()

        arrows = [box for box, cls in zip(boxes, classes) if cls == 0]
        objects = [box for box, cls in zip(boxes, classes) if cls == 1]

        for i, arrow in enumerate(arrows):
            arrow_center = [(arrow[0] + arrow[2]) / 2, (arrow[1] + arrow[3]) / 2]
            min_distance_px = float('inf')
            closest_obj = None

            for obj in objects:
                obj_center = [(obj[0] + obj[2]) / 2, (obj[1] + obj[3]) / 2]
                distance_px = math.dist(arrow_center, obj_center)
                if distance_px < min_distance_px:
                    min_distance_px = distance_px
                    closest_obj = obj

    # 3. Рисуем нарушения текста (зеленые прямоугольники)
    if text_violations_data and len(text_violations_data) > 0:
        results = model.predict(np.array(original_image), imgsz=640)
        boxes = results[0].boxes.xyxy.cpu().numpy()
        classes = results[0].boxes.cls.cpu().numpy()

        texts = [box for box, cls in zip(boxes, classes) if cls == 2]

        for i, text in enumerate(texts):
            draw.rectangle([text[0], text[1], text[2], text[3]],
                           outline=colors['text'], width=3)
            # Подпись для текста
            draw.text((text[0], text[1] - 20), f"Text {i + 1}",
                      fill=colors['text'])



    return final_image
