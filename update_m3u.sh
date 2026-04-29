#!/bin/bash

# URL origen
URL="https://ipfs.io/ipns/k2k4r8lm8tkmuxbc8lkmq1in3v0oya1p6pe9o5bu0hu30br5ko08k2gb/data/listas/lista_fuera_iptv.m3u"

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
