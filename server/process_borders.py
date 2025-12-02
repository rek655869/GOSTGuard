from PIL import Image, ImageDraw
import numpy as np
import cv2

# ГОСТы
GOST_TOP = 5
GOST_RIGHT = 5
GOST_BOTTOM = 5
GOST_LEFT = 20

# Размеры A3 в мм
A3_WIDTH_MM = 297
A3_HEIGHT_MM = 420

TOLERANCE = 0.6  # погрешность ±0.6 мм


def _pil_to_cv(img_pil: Image.Image):
    """PIL → OpenCV (BGR)"""
    if img_pil.mode == "RGBA":
        img_pil = img_pil.convert("RGB")
    img = np.array(img_pil)
    return cv2.cvtColor(img, cv2.COLOR_RGB2BGR)


def _cv_to_pil(img_cv):
    """OpenCV → PIL"""
    rgb = cv2.cvtColor(img_cv, cv2.COLOR_BGR2RGB)
    return Image.fromarray(rgb)


def _check(val, need, tol=TOLERANCE):
    """Проверка значения с погрешностью"""
    diff = abs(val - need)
    ok = (need - tol) <= val <= (need + tol)
    return diff, ok


def process_borders(image: Image.Image):
    """
    Возвращает изображение с рамкой и текст с проверкой размеров сторон.
    """

    img = _pil_to_cv(image)
    h, w = img.shape[:2]

    # коэффициенты px → mm
    px_to_mm_x = A3_WIDTH_MM / w
    px_to_mm_y = A3_HEIGHT_MM / h

    # поиск рамки
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    blur = cv2.GaussianBlur(gray, (5, 5), 0)
    edges = cv2.Canny(blur, 50, 150)

    contours, _ = cv2.findContours(edges, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)

    max_area = 0
    best_rect = None

    for cnt in contours:
        approx = cv2.approxPolyDP(cnt, 0.01 * cv2.arcLength(cnt, True), True)
        if len(approx) == 4:
            area = cv2.contourArea(approx)
            if area > max_area:
                max_area = area
                best_rect = approx

    if best_rect is None:
        raise ValueError("Рамка не найдена")

    x, y, rect_w, rect_h = cv2.boundingRect(best_rect)

    # переводим в мм
    dist_left_mm = x * px_to_mm_x
    dist_top_mm = y * px_to_mm_y
    dist_right_mm = (w - (x + rect_w)) * px_to_mm_x
    dist_bottom_mm = (h - (y + rect_h)) * px_to_mm_y

    # проверяем границы
    errors = []

    def add_check(name, val, gost):
        diff, ok = _check(val, gost)
        if not ok:
            errors.append(
                f"{name}: {val:.2f} мм (отклонение {diff:.2f} мм, требуется {gost} мм ±{TOLERANCE} мм)"
            )

    add_check("Слева", dist_left_mm, GOST_LEFT)
    add_check("Сверху", dist_top_mm, GOST_TOP)
    add_check("Справа", dist_right_mm, GOST_RIGHT)
    add_check("Снизу", dist_bottom_mm, GOST_BOTTOM)

    # рисуем рамку
    cv2.rectangle(img, (x, y), (x + rect_w, y + rect_h), (0, 255, 0), 4)
    output_pil = _cv_to_pil(img)

    if len(errors) == 0:
        errors.append("Все стороны соответствуют размерам")

    text = "\n".join(errors)

    return output_pil, text