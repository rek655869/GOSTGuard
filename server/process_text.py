import numpy as np
from PIL import Image, ImageDraw

def process_text(image: np.ndarray, model):
    """
    Проверяет текст по ГОСТ
    Только ошибки красным
    """
    pil_image = Image.fromarray(image)
    draw = ImageDraw.Draw(pil_image)

    results = model.predict(image, imgsz=640)
    boxes = results[0].boxes.xyxy.cpu().numpy()
    classes = results[0].boxes.cls.cpu().numpy()

    texts = [box for box, cls in zip(boxes, classes) if cls == 2]

    violations = []
    warnings = []
    statistics = {
        'total_texts': len(texts)
    }

    if len(texts) == 0:
        return violations, warnings, statistics, "Ошибок нет", pil_image

    # ИСПРАВЛЕННЫЙ КОЭФФИЦИЕНТ
    px_to_mm = 0.15

    # Целевые размеры в мм
    TEXT_HEIGHT_TARGET_MM = 3.5
    TEXT_HEIGHT_TOLERANCE_MM = 0.5

    for i, text in enumerate(texts):
        text_height_px = text[3] - text[1]
        text_height_mm = text_height_px * px_to_mm

        if not (TEXT_HEIGHT_TARGET_MM - TEXT_HEIGHT_TOLERANCE_MM <= text_height_mm <= TEXT_HEIGHT_TARGET_MM + TEXT_HEIGHT_TOLERANCE_MM):
            violation_text = f"Текст {i + 1} ({text_height_mm:.1f} мм) не соответствует {TEXT_HEIGHT_TARGET_MM} мм ±{TEXT_HEIGHT_TOLERANCE_MM}мм"
            violations.append(violation_text)
            draw.rectangle([text[0], text[1], text[2], text[3]], outline="red", width=3)

    result_text = "\n".join(violations) if violations else "Весь текст соответствует ГОСТ"

    return violations, warnings, statistics, result_text, pil_image