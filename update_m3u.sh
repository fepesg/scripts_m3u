#!/bin/bash

# URL de la lista M3U
url="AQUI VA LA URL DE LA LISTA M3U"
output_file="/home/ListaNewEra.m3u"

# Descargar la lista
curl -s "$url" -o "lista_temp.m3u"

# Asegurar que el archivo termina con un salto de línea
sed -i -e '$a\' "lista_temp.m3u"

pid=1

# Crear un archivo de salida vacío
> "$output_file"

# Usar cat para evitar problemas con la última línea
cat "lista_temp.m3u" | while IFS= read -r line || [[ -n "$line" ]]; do
    # Escribir la línea en el nuevo archivo
    if [[ $line =~ ^http ]]; then
        echo "$line&pid=$pid" >> "$output_file"
        ((pid++))
    else
        echo "$line" >> "$output_file"
    fi
done

# Limpiar archivo temporal
rm "lista_temp.m3u"

echo "Modificación completada. Archivo guardado como $output_file"
