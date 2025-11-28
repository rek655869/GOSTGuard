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
    final_image = original_image.copy()
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


def process_image(image: Image.Image, model):
    """
    image: PIL.Image
    Возвращает изображение с рамкой, номер (1) и текст с проверкой размеров сторон.
    """

    # Преобразуем PIL -> numpy
    img_array = np.array(image)

    # Получаем предсказания YOLO
    results = model.predict(img_array, imgsz=640)
    boxes = results[0].boxes.xyxy.cpu().numpy()  # [[x1, y1, x2, y2], ...]

    draw = ImageDraw.Draw(image)

    if len(boxes) == 0:
        return image, 0, "Объекты не обнаружены"

    # Находим самый большой бокс
    areas = [(x2 - x1) * (y2 - y1) for x1, y1, x2, y2 in boxes]
    max_idx = np.argmax(areas)
    x1, y1, x2, y2 = boxes[max_idx]

    # Рисуем рамку
    draw.rectangle([x1, y1, x2, y2], outline="red", width=3)


    # Проверка размеров сторон рамки
    left_width_px = x1
    right_width_px = image.width - x2
    top_height_px = y1
    bottom_height_px = image.height - y2

    # Переводим в миллиметры
    dpi = 70
    px_to_mm = 25.4 / dpi
    left_width = left_width_px * px_to_mm
    right_width = right_width_px * px_to_mm
    top_height = top_height_px * px_to_mm
    bottom_height = bottom_height_px * px_to_mm

    # Целевые размеры в мм
    left_target = 20
    other_target = 5
    tolerance = 0.2  # ±10%

    results_text = []

    def check_side(name: str, actual: float, target: float):
        lower = target * (1 - tolerance)
        upper = target * (1 + tolerance)
        if not (lower <= actual <= upper):
            results_text.append(
                f"{name} ({actual:.2f} мм) не соответствует {target} мм ±10%"
            )

    check_side("Левая сторона", left_width, left_target)
    check_side("Правая сторона", right_width, other_target)
    check_side("Верх", top_height, other_target)
    check_side("Низ", bottom_height, other_target)

    if not results_text:
        results_text.append("Все стороны соответствуют размерам")

    text = "\n".join(results_text)

    return image, text