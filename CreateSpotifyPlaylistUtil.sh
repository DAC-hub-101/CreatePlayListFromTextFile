#!/bin/bash

# ==============================================================================
# ЗАГЛАВИЕ: Spotify Playlist Importer (Fixed & Final)
# ==============================================================================

# -------------------------- КОНФИГУРАЦИЯ --------------------------

# ТВОЯТ ТОКЕН (Ако даде грешка 401, вземи нов от браузъра с F12)
ACCESS_TOKEN=" "

INPUT_FILE="playlist.txt"
NOT_FOUND_FILE="missing_tracks.txt"
PLAYLIST_NAME="Imported Playlist $(date '+%Y-%m-%d %H:%M')"
API_URL="https://api.spotify.com/v1"

# -------------------------- ПРОВЕРКИ --------------------------

for cmd in curl jq; do
    if ! command -v $cmd &> /dev/null; then
        echo "ГРЕШКА: $cmd не е инсталиран. Инсталирайте го (sudo apt install $cmd)"
        exit 1
    fi
done

if [ ! -f "$INPUT_FILE" ]; then
    echo "ГРЕШКА: Входният файл $INPUT_FILE не съществува."
    echo "Моля създайте файл 'playlist.txt' и напишете песните вътре."
    exit 1
fi

# Изчистване на файла за липсващи песни
> "$NOT_FOUND_FILE"

# -------------------------- ФУНКЦИИ --------------------------

urlencode() {
    echo -n "$1" | jq -sRr @uri
}

# Търсене на песен и връщане на URI
search_track() {
    local query="$1"
    local token="$2"
    
    # Използваме -G за GET заявка с параметри
    curl -s -G "$API_URL/search" \
        --data-urlencode "q=$query" \
        -d "type=track" \
        -d "limit=1" \
        -H "Authorization: Bearer $token" | \
        jq -r '.tracks.items[0].uri // empty'
}

# Създаване на плейлиста
create_playlist() {
    local user_id="$1"
    local token="$2"
    
    local body=$(jq -n \
        --arg n "$PLAYLIST_NAME" \
        --arg d "Created via Bash Script" \
        '{name: $n, description: $d, public: false}')
        
    curl -s -X POST "$API_URL/users/$user_id/playlists" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "$body" | jq -r '.id'
}

# Добавяне на масив от URI адреси
add_tracks_batch() {
    local playlist_id="$1"
    local token="$2"
    shift 2
    local uris=("$@")
    
    if [ ${#uris[@]} -eq 0 ]; then return; fi
    
    echo "  -> Добавяне на партида от ${#uris[@]} песни..."
    
    local json_uris=$(printf '%s\n' "${uris[@]}" | jq -R . | jq -s .)
    local body=$(jq -n --argjson u "$json_uris" '{uris: $u}')
    
    curl -s -X POST "$API_URL/playlists/$playlist_id/tracks" \
        -H "Authorization: Bearer $token" \
        -H "Content-Type: application/json" \
        -d "$body" > /dev/null
}

# -------------------------- MAIN --------------------------

echo "=== Стартиране на Spotify Importer ==="
echo "Използване на ръчен Token..."

# 1. Вземане на User ID (Тества дали токенът работи)
USER_ID=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" "$API_URL/me" | jq -r '.id')

if [[ "$USER_ID" == "null" || -z "$USER_ID" ]]; then
    echo "ГРЕШКА: Токенът е невалиден или изтекъл! Вземете нов от браузъра (F12 -> Network)."
    exit 1
fi

echo "Успешен вход като потребител: $USER_ID"

# 2. Създаване на плейлиста
PLAYLIST_ID=$(create_playlist "$USER_ID" "$ACCESS_TOKEN")
echo "Създадена плейлиста: $PLAYLIST_NAME (ID: $PLAYLIST_ID)"

# 3. Обработка на файла
URI_BUFFER=()
BATCH_LIMIT=100

echo "Обработка на песни от $INPUT_FILE..."

while IFS= read -r line || [[ -n "$line" ]]; do
    # Поправено: track_name (махнато е излишното 'i' отпред)
    # sed чисти интервали, но пази кавичките в имената (Don't, I'm)
    track_name=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [[ -z "$track_name" ]]; then continue; fi
    
    echo -n "Търсене: '$track_name'... "
    
    uri=$(search_track "$track_name" "$ACCESS_TOKEN")
    
    if [[ -n "$uri" ]]; then
        echo "OK"
        URI_BUFFER+=("$uri")
        
        # Проверка за пълен буфер (100 песни)
        if [ "${#URI_BUFFER[@]}" -eq "$BATCH_LIMIT" ]; then
            add_tracks_batch "$PLAYLIST_ID" "$ACCESS_TOKEN" "${URI_BUFFER[@]}"
            URI_BUFFER=() 
        fi
    else
        echo "НЕНАМЕРЕНА"
        echo "$track_name" >> "$NOT_FOUND_FILE"
    fi
    
done < "$INPUT_FILE"

# 4. Добавяне на останалите песни (Изчистване на буфера)
if [ "${#URI_BUFFER[@]}" -gt 0 ]; then
    echo "  -> Изчистване на буфера..."
    add_tracks_batch "$PLAYLIST_ID" "$ACCESS_TOKEN" "${URI_BUFFER[@]}"
fi

echo "=== Готово! ==="
echo "Липсващите песни са записани в $NOT_FOUND_FILE"
