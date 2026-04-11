import fitz  # PyMuPDF
import sys
import os

def render_pdf(pdf_path, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    doc = fitz.open(pdf_path)
    
    print(f"Renderizando {len(doc)} páginas desde {pdf_path}")
    
    saved_files = []
    for i in range(len(doc)):
        page = doc.load_page(i)
        
        # Aumentar la resolución para mejor legibilidad
        zoom_x = 2.0  
        zoom_y = 2.0  
        mat = fitz.Matrix(zoom_x, zoom_y)
        
        pix = page.get_pixmap(matrix=mat)
        out_path = os.path.join(output_dir, f"pagina_{i+1}.png")
        pix.save(out_path)
        saved_files.append(out_path)
        print(f"VISTA_PREVIA_GENERADA: {out_path}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Uso: python render_pdf.py <archivo.pdf> <directorio_salida>")
        sys.exit(1)
        
    render_pdf(sys.argv[1], sys.argv[2])
