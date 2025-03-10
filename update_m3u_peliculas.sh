#!/bin/bash

# Ruta del archivo de salida
OUTPUT_FILE="/home/ListaPeliculas.m3u"

# Descargar el archivo M3U
TEMP_FILE=$(mktemp)
wget -q -O "$TEMP_FILE" "AQUI VA LA URL DE LA LISTA M3U"

# Verificar si la descarga fue exitosa
if [[ ! -s "$TEMP_FILE" ]]; then
    echo "Error: No se pudo descargar el archivo M3U."
    exit 1
fi

# Eliminar caracteres ^M (CR)
sed -i 's/\r//' "$TEMP_FILE"

# Asegurar que el archivo termina con un salto de línea
sed -i -e '$a\' "$TEMP_FILE"

# Procesar el archivo
PID=1001
# Crear un archivo de salida vacío
> "$OUTPUT_FILE"

# Usar cat para evitar problemas con la última línea
cat "$TEMP_FILE" | while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == \#EXTINF:* ]]; then
        # Añadir group-title="PELICULAS" entre #EXTINF:-1 y tvg-logo
        line=$(echo "$line" | sed 's/\(#EXTINF:-1\)/\1 group-title="PELICULAS"/')
        echo "$line" >> "$OUTPUT_FILE"
    elif [[ "$line" == acestream://* ]]; then
        HASH="${line#acestream://}"
        # Añadir solo el enlace procesado, no la línea original
        echo "http://127.0.0.1:6878/ace/getstream?id=$HASH&pid=$PID" >> "$OUTPUT_FILE"
        ((PID++))
    else
        echo "$line" >> "$OUTPUT_FILE"
    fi
done

# Limpiar archivos temporales
rm -f "$TEMP_FILE"

echo "Archivo procesado y guardado en: $OUTPUT_FILE"
