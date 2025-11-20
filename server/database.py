from sqlite3 import connect
from io import BytesIO

def create_db():
    conn = connect('drawings.db')
    cursor = conn.cursor()
    cursor.execute('''
                       CREATE TABLE drawings
                       (
                           id              INTEGER PRIMARY KEY AUTOINCREMENT,
                           session_id      TEXT NOT NULL,
                           filename        TEXT NOT NULL,
                           processed_image BLOB,
                           status          TEXT      DEFAULT 'pending',
                           check_result    TEXT,
                           created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                       )
                       ''')
    conn.commit()
    conn.close()

def save_drawing_to_db(session_id, filename, processed_image, check_result):
    try:
        conn = connect('drawings.db')
        cursor = conn.cursor()

        buffered = BytesIO()
        processed_image.save(buffered, format="PNG")
        image_bytes = buffered.getvalue()

        cursor.execute('''
                       INSERT INTO drawings (session_id, filename, processed_image, status, check_result)
                       VALUES (?, ?, ?, ?, ?)
                       ''', (session_id, filename, image_bytes, 'checked', check_result))

        conn.commit()
        drawing_id = cursor.lastrowid
        conn.close()

        return drawing_id
    except Exception as e:
        print(f"Database error: {e}")
        return None

def get_history(session_id):
    try:
        conn = connect('drawings.db')
        cursor = conn.cursor()

        cursor.execute('''
                               SELECT id, filename, status, check_result, created_at
                               FROM drawings
                               WHERE session_id = ?
                               ORDER BY created_at DESC
                               ''', (session_id,))

        drawings = cursor.fetchall()
        conn.close()

        return drawings
    except Exception as e:
        print(f"Database error: {e}")
        return None

def get_drawing(drawing_id):
    try:
        conn = connect('drawings.db')
        cursor = conn.cursor()

        cursor.execute('''
                       SELECT processed_image, filename, check_result, status
                       FROM drawings 
                       WHERE id = ?
                   ''', (drawing_id,))

        row = cursor.fetchone()
        conn.close()

        return row
    except Exception as e:
        print(f"Database error: {e}")
        return None
