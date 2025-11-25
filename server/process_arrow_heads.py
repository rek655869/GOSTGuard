import numpy as np
from PIL import Image, ImageDraw


def process_arrow_heads(image: np.ndarray, model):
    """
    Проверка наконечников стрелок по ГОСТ 2.307-68
    """
    pil_image = Image.fromarray(image)
    draw = ImageDraw.Draw(pil_image)

    results = model.predict(image, imgsz=640)
    boxes = results[0].boxes.xyxy.cpu().numpy()
    classes = results[0].boxes.cls.cpu().numpy()

    arrows = [box for box, cls in zip(boxes, classes) if cls == 0]
    violations = []
    statistics = {'total_arrows': len(arrows)}

    if len(arrows) == 0:
        return violations, statistics, "Ошибок нет", pil_image

    # ИСПРАВЛЕННЫЙ КОЭФФИЦИЕНТ - более реалистичный
    px_to_mm = 0.15  # 1px = 0.15mm (вместо 0.36 при dpi=70)

    # Целевые размеры в мм
    ARROW_HEAD_TARGET_MM = 4.0
    ARROW_HEAD_TOLERANCE_MM = 1.0

    for i, arrow in enumerate(arrows):
        width_px = arrow[2] - arrow[0]
        height_px = arrow[3] - arrow[1]
        arrow_size_px = max(width_px, height_px)
        arrow_size_mm = arrow_size_px * px_to_mm

        if not (
                ARROW_HEAD_TARGET_MM - ARROW_HEAD_TOLERANCE_MM <= arrow_size_mm <= ARROW_HEAD_TARGET_MM + ARROW_HEAD_TOLERANCE_MM):
            violations.append(f"Наконечник {i + 1} ({arrow_size_mm:.1f} мм) не соответствует ГОСТ 2.307-68 (4-5 мм)")
            draw.rectangle([arrow[0], arrow[1], arrow[2], arrow[3]], outline="red", width=3)

    result_text = "\n".join(violations) if violations else "Все наконечники соответствуют ГОСТ 2.307-68"
    return violations, statistics, result_text, pil_image