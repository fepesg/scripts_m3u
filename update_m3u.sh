#!/bin/bash

# URL origen
URL="https://ipfs.io/ipns/k2k4r8oqlcjxsritt5mczkcn4mmvcmymbqw7113fz2flkrerfwfps004/data/listas/lista_iptv.m3u"

# Archivo de salida
OUTPUT="/iptv/listaNewEra.m3u"

# Descargar y cambiar el puerto
curl -s "$URL" | sed 's/127.0.0.1:6878/Orchestrator:8000/g' > "$OUTPUT"


echo "Archivo modificado guardado en: $OUTPUT"
