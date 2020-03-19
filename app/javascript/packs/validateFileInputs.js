const MAX_FILE_SIZE_MB = Object.freeze({
  image: 2,
  video: 50,
});

const PERMITTED_FILE_TYPES = ['video', 'image'];

function removeErrorMessages(fileInput) {
  const errorMessages = fileInput.parentNode.querySelectorAll(
    'div.file-upload-error',
  );

  errorMessages.forEach(errorMessage => {
    errorMessage.remove();
  });
}

function addErrorMessage(fileInput, msg) {
  const fileInputField = fileInput;
  const error = document.createElement('div');
  error.style.color = 'red';
  error.innerHTML = msg;
  error.classList.add('file-upload-error');

  fileInputField.parentNode.insertBefore(error, fileInputField.nextSibling);
}

function handleFileSizeError(fileSizeErrorHandler, fileInput, file) {
  console.error(`File too big - ${file.name}`);
  const fileInputField = fileInput;
  fileInputField.value = null;

  if (fileSizeErrorHandler) {
    fileSizeErrorHandler();
  } else {
    addErrorMessage(fileInput, 'File size was too large, try a smaller file.');
  }
}

function handleFileTypeError(fileTypeErrorHandler, fileInput, file) {
  console.error(`Invalid file format - ${file.name} - ${file.type}`);

  const fileInputField = fileInput;
  fileInputField.value = null;

  if (fileTypeErrorHandler) {
    fileTypeErrorHandler();
  } else {
    addErrorMessage(fileInput, 'The file format was invalid.');
  }
}

const fileInputs = document.querySelectorAll('input[type="file"]');

fileInputs.forEach(fileInput => {
  fileInput.addEventListener('change', () => {
    removeErrorMessages(fileInput);
    const files = Array.from(fileInput.files);
    const permittedFileTypes =
      fileInput.dataset.permittedFileTypes || PERMITTED_FILE_TYPES;
    const {fileSizeErrorHandler} = fileInput.dataset;
    const {fileTypeErrorHandler} = fileInput.dataset;

    let {maxFileSizeMb} = fileInput.dataset;

    for (let i = 0; i < files.length; i += 1) {
      const file = files[i];
      const fileType = file.type.split('/')[0];
      const fileSizeMb = (file.size / (1024 * 1024)).toFixed(2);
      maxFileSizeMb = maxFileSizeMb || MAX_FILE_SIZE_MB[fileType];

      const isValidFileSize = fileSizeMb < maxFileSizeMb;

      if (!isValidFileSize) {
        handleFileSizeError(fileSizeErrorHandler, fileInput, file);
        break;
      }

      const isValidFileType = permittedFileTypes.includes(fileType);

      if (!isValidFileType) {
        handleFileTypeError(fileTypeErrorHandler, fileInput, file);
        break;
      }
    }
  });
});
