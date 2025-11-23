import math
import numpy as np
from PIL import Image, ImageDraw


def process_arrow_distances(image: np.ndarray, model):
    """
    Проверка расстояний от стрелок до объектов по ГОСТ 2.307-68
    """
    pil_image = Image.fromarray(image)
    draw = ImageDraw.Draw(pil_image)

    results = model.predict(image, imgsz=640)
    boxes = results[0].boxes.xyxy.cpu().numpy()
    classes = results[0].boxes.cls.cpu().numpy()

    arrows = [box for box, cls in zip(boxes, classes) if cls == 0]
    objects = [box for box, cls in zip(boxes, classes) if cls == 1]
    violations = []
    statistics = {'total_arrows': len(arrows), 'total_objects': len(objects)}

    if len(arrows) == 0:
        return violations, statistics, "Ошибок нет", pil_image

    # ИСПРАВЛЕННЫЙ КОЭФФИЦИЕНТ
    px_to_mm = 0.15

    # Целевые размеры в мм
    DISTANCE_TARGET_MM = 10.0
    DISTANCE_TOLERANCE_MM = 3.0

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

        if closest_obj is not None:
            distance_mm = min_distance_px * px_to_mm
            obj_center = [(closest_obj[0] + closest_obj[2]) / 2, (closest_obj[1] + closest_obj[3]) / 2]

            if not (
                    DISTANCE_TARGET_MM - DISTANCE_TOLERANCE_MM <= distance_mm <= DISTANCE_TARGET_MM + DISTANCE_TOLERANCE_MM):
                violations.append(
                    f"Расстояние стрелки {i + 1} ({distance_mm:.1f} мм) не соответствует ГОСТ 2.307-68 (8-12 мм)")
                draw.line([arrow_center[0], arrow_center[1], obj_center[0], obj_center[1]], fill="red", width=3)

    result_text = "\n".join(violations) if violations else "Все расстояния соответствуют ГОСТ 2.307-68"
    return violations, statistics, result_text, pil_image