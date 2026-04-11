#!/bin/bash
# Script para generar el PDF desde la versión web local y extraer sus páginas como imágenes.
# Esto asegura que el PDF sea visualmente inspeccionado en cada nueva versión.

# 1. Definir la carpeta de la nueva versión (buscando el próximo número disponible)
VERSION=1
while [ -d "versiones/v$VERSION" ]; do
  ((VERSION++))
done

DIR="versiones/v$VERSION"
mkdir -p "$DIR"

echo "======================================"
echo "🚀 Generando PDF versión $VERSION"
echo "Carpeta destino: $DIR"
echo "======================================"

# 2. Generar el PDF usando Chrome Headless (asegúrate de tener el servidor http ejecutándose)
# Si te da error de conexión, recuerda ejecutar antes: python3 -m http.server 8765
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
    --headless \
    --disable-gpu \
    --print-to-pdf="$DIR/laboratorio-de-tesis.pdf" \
    --no-margins \
    "http://localhost:8765/guia-grupo3.html" >/dev/null 2>&1

if [ ! -f "$DIR/laboratorio-de-tesis.pdf" ]; then
    echo "❌ Error al generar el PDF. Revisa si el servidor local está prendido (http://localhost:8765)"
    exit 1
fi

echo "✅ PDF generado correctamente."

# 3. Renderizar las imágenes de prueba usando el script en Python
echo "📸 Generando renders de control de cada página..."
source pdf_env/bin/activate
python render_pdf.py "$DIR/laboratorio-de-tesis.pdf" "$DIR/renders"

echo "======================================"
echo "🎉 ¡Flujo completado con éxito!"
echo "Revisa el PDF y los PNGs renderizados en: $DIR/"
echo "======================================"
