import math
import numpy as np
from PIL import Image, ImageDraw


def process_arrow_distances(image: np.ndarray, model):
    """
    Проверка расстояний от наконечников стрелок до объектов по ГОСТ 2.307-68
    """
    pil_image = Image.fromarray(image)

    results = model.predict(image, imgsz=640)
    boxes = results[0].boxes.xyxy.cpu().numpy()
    classes = results[0].boxes.cls.cpu().numpy()

    arrows = [box for box, cls in zip(boxes, classes) if cls == 0]
    objects = [box for box, cls in zip(boxes, classes) if cls == 1]

    violations = []
    warnings = []
    statistics = {
        'total_arrows': len(arrows),
        'total_objects': len(objects),
        'matched_pairs': 0
    }

    if len(arrows) == 0:
        return violations, statistics, "Стрелки не обнаружены", pil_image

    px_to_mm = 0.15

    # Группируем стрелки по объектам
    object_arrows = {}

    for i, arrow in enumerate(arrows):
        arrow_center = [(arrow[0] + arrow[2]) / 2, (arrow[1] + arrow[3]) / 2]
        min_distance_px = float('inf')
        closest_obj_idx = None

        for j, obj in enumerate(objects):
            obj_center = [(obj[0] + obj[2]) / 2, (obj[1] + obj[3]) / 2]
            distance_px = math.dist(arrow_center, obj_center)
            if distance_px < min_distance_px:
                min_distance_px = distance_px
                closest_obj_idx = j

        if closest_obj_idx is not None:
            if closest_obj_idx not in object_arrows:
                object_arrows[closest_obj_idx] = []
            object_arrows[closest_obj_idx].append((i, arrow, min_distance_px))

    # Проверяем расстояния для каждой группы
    for obj_idx, arrows_data in object_arrows.items():
        arrows_data.sort(key=lambda x: x[2])  # сортируем по расстоянию

        for order, (arrow_idx, arrow, distance_px) in enumerate(arrows_data):
            distance_mm = distance_px * px_to_mm

            # Правило: первая стрелка - 10±2 мм, последующие - 7±2 мм
            if order == 0:
                target_min, target_max = 8.0, 12.0
                arrow_type = "первая"
            else:
                target_min, target_max = 5.0, 9.0
                arrow_type = f"{order + 1}-я"

            if not (target_min <= distance_mm <= target_max):
                violations.append(
                    f"{arrow_type.capitalize()} стрелка {arrow_idx + 1}: расстояние {distance_mm:.1f} мм "
                    f"вне диапазона {target_min}-{target_max} мм"
                )
            else:
                warnings.append(
                    f"{arrow_type.capitalize()} стрелка {arrow_idx + 1}: расстояние {distance_mm:.1f} мм - норма"
                )

    # Формируем итоговый текст
    result_lines = []

    if violations:
        result_lines.append("🔴 Нарушения ГОСТ:")
        result_lines.extend(violations)

    if warnings:
        if result_lines:
            result_lines.append("")
        result_lines.append("🟡 Корректные расстояния:")
        result_lines.extend(warnings)

    if not result_lines:
        result_lines.append("✅ Все расстояния соответствуют ГОСТ")

    result_text = "\n".join(result_lines)

    return violations, statistics, result_text, pil_image