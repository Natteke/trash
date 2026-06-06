#!/bin/bash

# ==========================================
# 1. ОСНОВНЫЕ ПЕРЕМЕННЫЕ
# ==========================================
VIDEO_URL="https://www.youtube.com/watch?v=1JFefTdgWbc"
START_TIME="00:00:13.500" # Начало (формат ЧЧ:ММ:СС или просто секунды)
END_TIME="00:00:16.500"   # Конец (формат ЧЧ:ММ:СС или просто секунды)
OUTPUT_DIR="/Users/andrei/projects/trash/audio/dnd/bard"
# Формат на выходе (mp3, ogg, wav)
AUDIO_EXT="ogg"

# ------------------------------------------
# ЛОГИКА СКРИПТА
# ------------------------------------------

# Создаем папку назначения, если её еще нет
mkdir -p "$OUTPUT_DIR"

# Создаем безопасную временную папку в /tmp
TMP_DIR=$(mktemp -d)
echo "📁 Временная папка создана: $TMP_DIR"

echo "⬇️  Скачиваем видео с помощью yt-dlp..."
# Скачиваем файл. 
# Используем параметр bestaudio, чтобы не тратить время на скачивание видеоряда, 
# --print after_move:filepath позволяет скрипту "поймать" точный путь к скачанному файлу.
DOWNLOADED_FILE=$(yt-dlp -f "bestaudio/best" \
    -o "$TMP_DIR/%(title)s.%(ext)s" \
    --print after_move:filepath \
    "$VIDEO_URL")

# Проверка: удалось ли скачать файл
if [ -z "$DOWNLOADED_FILE" ] || [ ! -f "$DOWNLOADED_FILE" ]; then
    echo "❌ Ошибка: Не удалось скачать файл."
    rm -rf "$TMP_DIR"
    exit 1
fi

echo "✅ Файл успешно скачан: $DOWNLOADED_FILE"

# Достаем имя файла (без пути и без оригинального расширения)
BASENAME=$(basename "$DOWNLOADED_FILE")
FILENAME="${BASENAME%.*}"

# Формируем итоговый путь для сохранения
OUTPUT_FILE="$OUTPUT_DIR/$FILENAME.$AUDIO_EXT"

echo "✂️  Вырезаем аудио с $START_TIME по $END_TIME с помощью ffmpeg..."
# Запускаем ffmpeg:
# -y  : перезаписать файл на выходе, если он уже есть
# -i  : входящий файл
# -ss : время начала
# -to : время окончания
# -vn : игнорировать видеопоток (на всякий случай)
# -q:a 2 : высокое качество аудио (для mp3)
ffmpeg -y -i "$DOWNLOADED_FILE" \
    -ss "$START_TIME" \
    -to "$END_TIME" \
    -vn \
    -q:a 2 \
    "$OUTPUT_FILE" \
    -hide_banner -loglevel error

# Проверка успешности ffmpeg
if [ $? -eq 0 ]; then
    echo "🎉 Готово! Аудио сохранено:"
    echo "➡️  $OUTPUT_FILE"
else
    echo "❌ Ошибка при обработке ffmpeg."
fi

# Очистка: удаляем временную папку вместе с исходником
echo "🧹 Удаляем временные файлы..."
rm -rf "$TMP_DIR"
