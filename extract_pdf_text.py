import fitz
import sys

def extract_text(pdf_path):
    doc = fitz.open(pdf_path)
    text = ""
    for page in doc:
        text += page.get_text()
    return text

if __name__ == "__main__":
    pdf_path = "mi guion_ sesiones sincronicas.pdf"
    try:
        content = extract_text(pdf_path)
        print(content)
    except Exception as e:
        print(f"Error: {e}")
