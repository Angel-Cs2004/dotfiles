#!/bin/bash
texto=$(wl-paste 2>/dev/null | tr '\n' ' ' | sed 's/  */ /g')

if [ -z "$texto" ]; then
    zenity --warning --title="Traductor" --text="No hay texto en el portapapeles." --width=300
    exit 1
fi

traduccion=$(echo "$texto" | claude -p "Traduce al español el siguiente texto. Responde ÚNICAMENTE con la traducción, sin explicaciones ni comentarios:" 2>/dev/null)

if [ -z "$traduccion" ]; then
    zenity --warning --title="Traductor" --text="No se pudo traducir." --width=300
    exit 1
fi

zenity --info \
    --title="Traducción (Claude AI)" \
    --text="<b>Original:</b>\n$texto\n\n<b>Traducción:</b>\n$traduccion" \
    --width=500 \
    --height=250
