#!/bin/bash

# URL origen
URL="https://raw.githubusercontent.com/fepesg/scripts_m3u/refs/heads/main/lista.m3u"

# Archivo de salida
OUTPUT="/iptv/listaNewEra.m3u"

# Descargar y modificar
curl -s "$URL" | awk '
BEGIN {chno=1}
{
  if ($0 ~ /^#EXTINF:/) {
    # Si ya existe tvg-chno= lo reemplaza, si no, lo agrega
    if ($0 ~ /tvg-chno="/) {
      sub(/tvg-chno="[0-9]*"/, "tvg-chno=\"" chno "\"")
    } else {
      sub(/#EXTINF:-1/, "#EXTINF:-1 tvg-chno=\"" chno "\"")
    }
    chno++
  }
  gsub(/127\.0\.0\.1:6878/, "Orchestrator:8000")
  print
}' > "$OUTPUT"

echo "Archivo modificado guardado en: $OUTPUT"
