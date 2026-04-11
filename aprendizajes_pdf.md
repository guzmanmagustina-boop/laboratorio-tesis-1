# Aprendizajes del Renderizado a PDF

Este documento registra los aprendizajes y el flujo de trabajo implementado para exportar presentaciones en base HTML dinámicas a archivos `.pdf` garantizando su formato e integridad visual.

## 1. El Problema: Elementos Ocultos en *Headless Print*
Al rediseñar la presentación interactiva con animaciones de scroll modernas (donde las tarjetas de contenido tienen `opacity: 0` hasta que entran en la pantalla por el *scroll*), nos enfrentamos a un problema severo de exportación:
La herramienta de impresión automatizada de Google Chrome evaluaba la página visualmente estática. Sin haber ningún evento de *scroll*, los elementos mantenían su opacidad invisible. **El PDF resultante salía con las páginas completamente en blanco** y carecía de todo el contenido interactivo y tarjetas.

## 2. La Solución: Override de Medios de Impresión (`@media print`)
Aprendimos que para evitar que el estado inicial de estas animaciones rompa los generadores de PDF, se debe interceptar a nivel CSS el momento en el que se intenta imprimir el documento. 

Agregando la siguiente regla al final de la etiqueta `<style>` garantizamos que al instante que se active el render de impresión, todos los elementos se hagan completamente corpóreos e ignoren sus transiciones CSS:
```css
@media print {
  /* Anula opacidades y transformaciones invisibles */
  .step-card, .check-item, .example-box, .tl-item, .callout, .obj-card, .accordion-item, .full-example {
    opacity: 1 !important;
    transform: none !important;
    transition: none !important;
  }
  
  /* Fuerza el despliegue de elementos agrupados/ocultos como menús desplegables */
  .accordion-body { max-height: none !important; overflow: visible !important; }
  
  /* Oculta la barra de progreso ya que no tiene sentido en formato estático */
  .progress-nav { display: none !important; }
}
```

## 3. Feedback Visual Automatizado (`render_pdf.py`)
Confiar a ciegas en la salida del PDF genera riesgos de enviar el documento a los alumnos en formatos rotos.
Implementamos un script de **Python (utilizando PyMuPDF)**, el cual extrae internamente cada página generada de manera individual y las renderiza en archivos `.png` independientes.

**Por qué hacemos esto:**
- Podemos hojear rápidamente las previsualizaciones `.png` para confirmar de un pantallazo rápido si el PDF final cuenta con los espacios de diseño acordados.
- Detectar temprano saltos de línea incorrectos o elementos gráficos cortados por las páginas del PDF.

## 4. Estructura de Automatización de Versiones
Para evitar sobreescribir renders y perder historial, se consolidó todo en el flujo automatizado a través de un shell script (`generar_pdf.sh`). 

**Flujo en cascada final:**
1. Ejecutar el script buscará la próxima carpeta con su propio versionado (ej. `versiones/v1/`).
2. Se hace la llamada a `Chrome --headless` con `--print-to-pdf`.
3. Se genera un trigger al entorno virtual de Python para que ejecute `render_pdf.py`.
4. El output queda empaquetado herméticamente de la siguiente forma:
   ```text
   📁 versiones/
     📁 v1/
       📄 laboratorio-de-tesis.pdf
       📁 renders/
         🖼 pagina_1.png
         🖼 pagina_X.png ...
   ```
Este estándar debe ser utilizado de aquí en adelante frente a cualquier iteración visual de la guía interactiva.

## 5. El Problema: Filtros CSS modernos no soportados
Al revisar minuciosamente las imágenes de los PDF generados en la versión 1, descubrimos incompatibilidades de renderizado propias de casi todo motor gráfico destinado a PDFs estáticos (como el módulo de impresión de Chrome o macOS Preview):

1. **La propiedad `-webkit-background-clip: text`**: Nos permitía tener un *hero title* con un gradiente multicolor. Sin embargo, al imprimir el PDF, el motor falla en el "recorte" de la letra y termina dibujando un rectángulo sólido gigante que oculta la lectura del texto.
2. **La propiedad `backdrop-filter: blur(...)`**: Este "efecto vidrio" se utiliza para los botoncitos flotantes. El generador PDF, al no poder hacer *rendering* avanzado en segundo plano, reemplaza el filtro cristalino con una caja sólida de color gris por defecto, rompiendo toda estética de limpieza.

### ✨ Solución a filtros: Fallbacks sólidos
Al igual que arreglamos los objetos invisibles por las animaciones en *scroll*, la directiva a futuro es incluir inmediatamente dentro de la declaración `@media print` el re-establecimiento de todas estas características gráficas complejas a "colores planos":

```css
@media print {
  /* FIX: Anular el clip de texto con degradado por un color sólido común */
  .gradient-text {
    background: none !important;
    -webkit-text-fill-color: var(--c-accent1) !important;
    color: var(--c-accent1) !important;
  }
  
  /* FIX: Anular el difuminado dinámico por un fondo blanco absoluto y marco sutil */
  .cover-step-pill {
    backdrop-filter: none !important;
    -webkit-backdrop-filter: none !important;
    background: white !important;
    border: 2px solid rgba(0,0,0,0.05) !important;
  }
}
```
La regla de oro: **Lo que en web es "dinámico/transparente", en PDF debe forzarse a ser "estático/sólido" mediante el override de impresión**.
