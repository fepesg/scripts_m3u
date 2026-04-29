#!/bin/bash

# URL origen
URL="https://ipfs.io/ipns/k2k4r8lm8tkmuxbc8lkmq1in3v0oya1p6pe9o5bu0hu30br5ko08k2gb/data/listas/lista_iptv.m3u"

# Archivo de salida
OUTPUT="/iptv/listaNewEra.m3u"

# Archivo temporal
TMPFILE=$(mktemp)

echo "Descargando lista..."
curl -s "$URL" -o "$TMPFILE"

if [ ! -s "$TMPFILE" ]; then
    echo "Error: No se pudo descargar la lista o está vacía"
    rm -f "$TMPFILE"
    exit 1
fi

echo "Procesando..."

awk '
BEGIN { chno = 1; pending = 0 }

# ============================================================
# PRIMER PASO: contar cuántas veces aparece cada nombre limpio
# ============================================================
NR == FNR {
    if ($0 ~ /^#EXTINF:/) {
        # Extraer todo lo que hay después de la primera coma
        comma_pos = index($0, ",")
        name = substr($0, comma_pos + 1)
        gsub(/^[ \t]+|[ \t]+$/, "", name)   # trim

        # Eliminar sufijo " XXXX --> FUENTE" (4 hex chars + flecha + texto)
        sub(/ [0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F] -->.*$/, "", name)
        gsub(/^[ \t]+|[ \t]+$/, "", name)   # trim de nuevo

        count[name]++
    }
    next
}

# ============================================================
# SEGUNDO PASO: generar el archivo de salida
# ============================================================
{
    if ($0 ~ /^#EXTINF:/) {
        saved_extinf = $0

        # Extraer nombre limpio (mismo proceso que en el primer paso)
        comma_pos = index($0, ",")
        clean_name = substr($0, comma_pos + 1)
        gsub(/^[ \t]+|[ \t]+$/, "", clean_name)
        sub(/ [0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F] -->.*$/, "", clean_name)
        gsub(/^[ \t]+|[ \t]+$/, "", clean_name)

        saved_clean = clean_name
        saved_dup   = (count[clean_name] > 1)
        pending     = 1

    } else if (pending && $0 ~ /getstream\?id=/) {
        url = $0

        # Extraer el hash ID de acestream
        ace_id = url
        sub(/.*[?&]id=/, "", ace_id)
        sub(/[^0-9a-fA-F].*$/, "", ace_id)   # limpiar lo que haya tras el hash
        last4 = substr(ace_id, length(ace_id) - 3, 4)

        # Nombre final: con sufijo si hay duplicados, limpio si es único
        out_name = saved_dup ? (saved_clean " " last4) : saved_clean

        # Reconstruir la línea #EXTINF con el nuevo nombre
        comma_pos = index(saved_extinf, ",")
        attr_part = substr(saved_extinf, 1, comma_pos - 1)
        line = attr_part ", " out_name

        # Añadir o reemplazar tvg-chno
        if (line ~ /tvg-chno="/) {
            sub(/tvg-chno="[0-9]*"/, "tvg-chno=\"" chno "\"", line)
        } else {
            sub(/#EXTINF:-1/, "#EXTINF:-1 tvg-chno=\"" chno "\"", line)
        }
        chno++

        # Reemplazar IP en la línea EXTINF y en la URL
        gsub(/127\.0\.0\.1:6878/, "Orchestrator:8000", line)
        gsub(/127\.0\.0\.1:6878/, "Orchestrator:8000", url)

        print line
        print url

        pending = 0

    } else {
        # Cabeceras, líneas en blanco, etc.
        gsub(/127\.0\.0\.1:6878/, "Orchestrator:8000")
        print
    }
}
' "$TMPFILE" "$TMPFILE" > "$OUTPUT"

rm -f "$TMPFILE"
echo "Listo. Archivo guardado en: $OUTPUT"
