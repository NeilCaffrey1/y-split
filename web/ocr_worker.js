// OCR Web Worker to prevent UI blocking
importScripts('https://unpkg.com/tesseract.js@5/dist/tesseract.min.js');

self.onmessage = async function(e) {
  const { imageData, options } = e.data;
  
  try {
    console.log('OCR Worker: Starting OCR processing...');
    
    const { data: { text } } = await Tesseract.recognize(
      imageData,
      'eng',
      {
        logger: m => {
          // Send progress updates back to main thread
          if (m.status === 'recognizing text') {
            self.postMessage({
              type: 'progress',
              progress: m.progress
            });
          }
        }
      }
    );
    
    console.log('OCR Worker: OCR completed successfully');
    
    // Send result back to main thread
    self.postMessage({
      type: 'success',
      text: text
    });
    
  } catch (error) {
    console.error('OCR Worker: Error during OCR processing:', error);
    
    // Send error back to main thread
    self.postMessage({
      type: 'error',
      error: error.toString()
    });
  }
};