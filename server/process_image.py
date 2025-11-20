from PIL import Image, ImageDraw
import numpy as np
from ultralytics import YOLO

def process_image(image: Image.Image):
    """
    image: PIL.Image
    Возвращает изображение с рамкой, номер (1) и текст с проверкой размеров сторон.
    """
    model = YOLO("yolo11s.pt")

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
    number = 1

    return image, number, text