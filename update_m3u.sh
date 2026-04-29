#!/bin/bash

set -e

# URL origen
URL="https://ipfs.io/ipns/k2k4r8lm8tkmuxbc8lkmq1in3v0oya1p6pe9o5bu0hu30br5ko08k2gb/data/listas/lista_iptv.m3u"

# Host AceStream (tu contenedor)
ACESTREAM_HOST="Orchestrator:8000"

# Archivo de salida
OUTPUT="/iptv/listaNewEra.m3u"

# Archivo temporal
TMPFILE=$(mktemp)

echo "Descargando lista..."
echo "URL usada: [$URL]"

curl -L --fail --silent --show-error "$URL" -o "$TMPFILE"

if [ ! -s "$TMPFILE" ]; then
    echo "Error: No se pudo descargar la lista o está vacía"
    rm -f "$TMPFILE"
    exit 1
fi

echo "Procesando..."

awk -v host="$ACESTREAM_HOST" '
BEGIN { chno = 1; pending = 0 }

# ============================================================
# PRIMER PASO: contar nombres
# ============================================================
NR == FNR {
    if ($0 ~ /^#EXTINF:/) {
        comma_pos = index($0, ",")
        name = substr($0, comma_pos + 1)
        gsub(/^[ \t]+|[ \t]+$/, "", name)

        sub(/ [0-9a-fA-F]{4} -->.*$/, "", name)
        gsub(/^[ \t]+|[ \t]+$/, "", name)

        count[name]++
    }
    next
}

# ============================================================
# SEGUNDO PASO: generar salida limpia
# ============================================================
{
    if ($0 ~ /^#EXTINF:/) {
        saved_extinf = $0

        comma_pos = index($0, ",")
        clean_name = substr($0, comma_pos + 1)
        gsub(/^[ \t]+|[ \t]+$/, "", clean_name)

        sub(/ [0-9a-fA-F]{4} -->.*$/, "", clean_name)
        gsub(/^[ \t]+|[ \t]+$/, "", clean_name)

        saved_clean = clean_name
        saved_dup   = (count[clean_name] > 1)
        pending     = 1

    } else if (pending) {

        url = $0
        ace_id = ""

        # -------------------------------
        # Detectar formato
        # -------------------------------

        # acestream://HASH
        if (url ~ /^acestream:\/\//) {
            ace_id = url
            sub(/acestream:\/\//, "", ace_id)
        }

        # getstream?id=HASH
        else if (url ~ /getstream\?id=/) {
            ace_id = url
            sub(/.*[?&]id=/, "", ace_id)
        }

        # cualquier cosa con id=
        else if (url ~ /id=/) {
            ace_id = url
            sub(/.*id=/, "", ace_id)
        }

        # limpiar basura
        sub(/[^0-9a-fA-F].*$/, "", ace_id)

        # validar hash
        if (length(ace_id) < 10) {
            pending = 0
            next
        }

        last4 = substr(ace_id, length(ace_id) - 3, 4)

        out_name = saved_dup ? (saved_clean " " last4) : saved_clean

        comma_pos = index(saved_extinf, ",")
        attr_part = substr(saved_extinf, 1, comma_pos - 1)
        line = attr_part ", " out_name

        # tvg-chno
        if (line ~ /tvg-chno="/) {
            sub(/tvg-chno="[0-9]*"/, "tvg-chno=\"" chno "\"", line)
        } else {
            sub(/#EXTINF:-1/, "#EXTINF:-1 tvg-chno=\"" chno "\"", line)
        }
        chno++

        # -------------------------------
        # GENERAR URL FINAL VÁLIDA
        # -------------------------------
        url = "http://" host "/ace/getstream?id=" ace_id

        print line
        print url

        pending = 0

    } else {
        print
    }
}
' "$TMPFILE" "$TMPFILE" > "$OUTPUT"

rm -f "$TMPFILE"

echo "Listo. Archivo guardado en: $OUTPUT"
