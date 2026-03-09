async function runOCR(image) {
  const result = await Tesseract.recognize(image, 'eng');
  return result.data.text;
}