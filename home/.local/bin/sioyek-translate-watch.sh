#!/bin/bash

FLAG_VOZ="/tmp/sioyek_voice_on"
WORKER_PID_FILE="/tmp/sioyek_translate_worker_pid"
AUDIO_PID_FILE="/tmp/sioyek_ffplay_pid"
PENDING_TEXT_FILE="/tmp/sioyek_translate_pending_text"
TRANSLATE_CACHE_DIR="/tmp/sioyek_translate_cache.d"
AUDIO_CACHE_DIR="/tmp/sioyek_tts_cache.d"
DEBOUNCE_SECONDS="0.45"

mkdir -p "$TRANSLATE_CACHE_DIR" "$AUDIO_CACHE_DIR"

header() {
    if [ -f "$FLAG_VOZ" ]; then
        printf '\033[1m\033[38;5;111m  Traductor · Bing Translate  \033[38;5;114m [voz ON]\033[38;5;244m  v: cambiar\033[0m\n'
    else
        printf '\033[1m\033[38;5;111m  Traductor · Bing Translate  \033[38;5;244m [voz OFF]  v: cambiar\033[0m\n'
    fi
    printf '\033[38;5;59m  ──────────────────────────────────────\033[0m\n'
}

normalize_text() {
    tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//'
}

hash_text() {
    printf '%s' "$1" | sha256sum | awk '{print $1}'
}

translate_text() {
    local text="$1"

    trans -brief -no-ansi -e bing en:es "$text" 2>/dev/null
}

stop_audio() {
    if [ -f "$AUDIO_PID_FILE" ]; then
        kill "$(cat "$AUDIO_PID_FILE")" 2>/dev/null
        rm -f "$AUDIO_PID_FILE"
    fi
    pkill -P $$ ffplay 2>/dev/null
}

stop_worker() {
    if [ -f "$WORKER_PID_FILE" ]; then
        old_pid=$(cat "$WORKER_PID_FILE")
        if [ -n "$old_pid" ]; then
            kill "$old_pid" 2>/dev/null
            pkill -P "$old_pid" 2>/dev/null
        fi
        rm -f "$WORKER_PID_FILE"
    fi
}

toggle_voice() {
    if [ -f "$FLAG_VOZ" ]; then
        rm -f "$FLAG_VOZ"
        stop_audio
        notify-send "Sioyek Traductor" "Voz desactivada" -t 1500 -i audio-volume-muted
    else
        touch "$FLAG_VOZ"
        notify-send "Sioyek Traductor" "Voz activada" -t 1500 -i audio-volume-high
    fi

    clear
    header
    printf '\033[38;5;244m  Selecciona texto para traducir...\033[0m\n'
}

play_sentence_audio() {
    sentence="$1"
    [ -z "$sentence" ] && return 0
    [ -f "$FLAG_VOZ" ] || return 0

    audio_hash=$(hash_text "$sentence")
    audio_file="$AUDIO_CACHE_DIR/$audio_hash.mp3"

    if [ ! -s "$audio_file" ]; then
        $HOME/.local/bin/edge-tts --voice "es-AR-ElenaNeural" --text "$sentence" --write-media "$audio_file" >/dev/null 2>&1
    fi

    [ -s "$audio_file" ] || return 0
    [ -f "$FLAG_VOZ" ] || return 0

    ffplay -nodisp -autoexit -loglevel quiet "$audio_file" 2>/dev/null &
    echo $! > "$AUDIO_PID_FILE"
    wait "$!" 2>/dev/null
    rm -f "$AUDIO_PID_FILE"
}

play_translation_audio() {
    translation="$1"
    [ -f "$FLAG_VOZ" ] || return 0
    stop_audio

    printf '%s\n' "$translation" |
        sed 's/\([.!?]\)[[:space:]]\+/\1\n/g' |
        while IFS= read -r sentence || [ -n "$sentence" ]; do
            [ -f "$FLAG_VOZ" ] || break
            sentence=$(printf '%s' "$sentence" | normalize_text)
            play_sentence_audio "$sentence"
        done
}

worker() {
    sleep "$DEBOUNCE_SECONDS"

    [ -f "$PENDING_TEXT_FILE" ] || exit 0
    texto=$(cat "$PENDING_TEXT_FILE")
    [ -z "$texto" ] || [ ${#texto} -lt 3 ] && exit 0

    text_hash=$(hash_text "$texto")
    cache_file="$TRANSLATE_CACHE_DIR/$text_hash.txt"

    clear
    header
    printf "\033[1m\033[38;5;229m  Original:\033[0m\n  \033[38;5;252m%s\033[0m\n" "$texto"
    printf "\033[38;5;59m  ──────────────────────────────────────\033[0m\n"

    if [ -s "$cache_file" ]; then
        traduccion=$(cat "$cache_file")
        printf "\033[1m\033[38;5;114m  Traducción:\033[0m\n  \033[38;5;252m%s\033[0m\n" "$traduccion"
        printf "\033[38;5;59m  ──────────────────────────────────\033[38;5;244m [caché]\033[0m\n"
    else
        printf "\033[38;5;244m  traduciendo...\033[0m"
        traduccion=$(translate_text "$texto")
        printf "\r\033[2K"

        if [ -z "$traduccion" ]; then
            printf "\033[38;5;196m  No se pudo traducir.\033[0m\n"
            printf "\033[38;5;244m  Revisa tu conexión o ejecuta: trans -brief -no-ansi -e bing en:es 'hello world'\033[0m\n"
            exit 0
        fi

        printf "%s" "$traduccion" > "$cache_file"
        printf "\033[1m\033[38;5;114m  Traducción:\033[0m\n  \033[38;5;252m%s\033[0m\n" "$traduccion"
    fi

    play_translation_audio "$traduccion"
}

selection_event() {
    texto=$(normalize_text)
    [ -z "$texto" ] || [ ${#texto} -lt 3 ] && exit 0

    printf "%s" "$texto" > "$PENDING_TEXT_FILE"
    stop_worker
    stop_audio
    "$0" --worker &
    echo $! > "$WORKER_PID_FILE"
}

case "$1" in
    --selection-event)
        selection_event
        exit 0
        ;;
    --worker)
        worker
        exit 0
        ;;
esac

clear
header
printf '\033[38;5;244m  Selecciona texto para traducir...\033[0m\n'

wl-paste --primary --watch "$0" --selection-event &
WATCH_PID=$!

trap 'kill "$WATCH_PID" 2>/dev/null; stop_worker; stop_audio' EXIT

while IFS= read -rsn1 key; do
    case "$key" in
        v|V) toggle_voice ;;
        q|Q) break ;;
    esac
done

exit 0
