/**
 * @file Manages logic to validate file uploads client-side. In general, the
 * validations work by looping over input form fields with a type of file and
 * checking the size and format of the files upload by the user.
 */

/**
 * An object containing the top level MIME type as the key and the max file
 * size in MB for the value. To use a different value than these defaults,
 * simply add a data-max-file-mb attribute to the input form field with the
 * max file size in MB. If that attribute is found, it takes priority over these
 * defaults.
 *
 * @constant {Object.<string, number>}
 */
const MAX_FILE_SIZE_MB = Object.freeze({
  image: 25,
  video: 50,
});

/**
 * Permitted file types using the top level MIME type (i.e. image for
 * image/png). To specify permitted file types, simply add a
 * data-permitted-file-types attribute to the input form field as an Array of
 * strings specifying the top level MIME types that are permitted.
 *
 * @constant {string[]}
 */
const PERMITTED_FILE_TYPES = ['image'];

/**
 * Removes any pre-existing error messages from the DOM related to file
 * validation.
 *
 * @param {HTMLElement} fileInput - An input form field with type of file
 */
function removeErrorMessage(fileInput) {
  const errorMessage = fileInput.parentNode.querySelector(
    'div.file-upload-error',
  );

  if (errorMessage) {
    errorMessage.remove();
  }
}

/**
 * Adds error messages in the form of a div with red text.
 *
 * @param {HTMLElement} fileInput - An input form field with type of file
 * @param {string} msg - The error message to be displayed to the user
 *
 * @returns {HTMLElement} The error element that was added to the DOM
 */
function addErrorMessage(fileInput, msg) {
  const fileInputField = fileInput;
  const error = document.createElement('div');
  error.style.color = 'red';
  error.innerHTML = msg;
  error.classList.add('file-upload-error');

  fileInputField.parentNode.append(error);
}

/**
 * Handles errors for files that are too large.
 *
 * @param {object} fileSizeErrorHandler - A custom function to be ran after the default error handling
 * @param {HTMLElement} fileInput - An input form field with type of file
 * @param {number} fileSizeMb - The size of the file in MB
 * @param {?number} maxFileSizeMb - The max file size limit in MB
 */
function handleFileSizeError(
  fileSizeErrorHandler,
  fileInput,
  fileSizeMb,
  maxFileSizeMb,
) {
  const fileInputField = fileInput;
  fileInputField.value = null;

  if (fileSizeErrorHandler) {
    fileSizeErrorHandler();
  } else {
    let errorMessage = `File size too large (${fileSizeMb} MB).`;

    // If a user uploads a file type that we haven't defined a max size limit for then maxFileSizeMb
    // could be NaN
    if (maxFileSizeMb >= 0) {
      errorMessage += ` The limit is ${maxFileSizeMb} MB.`;
    }

    addErrorMessage(fileInput, errorMessage);
  }
}

/**
 * Handles errors for files that are not a valid format.
 *
 * @param {object} fileSizeErrorHandler - A custom function to be ran after the default error handling
 * @param {HTMLElement} fileInput - An input form field with type of file
 * @param {string} fileType - The top level file type (i.e. image for image/png)
 * @param {string[]} permittedFileTypes - The top level file types (i.e. image for image/png) that are permitted
 */
function handleFileTypeError(
  fileTypeErrorHandler,
  fileInput,
  fileType,
  permittedFileTypes,
) {
  const fileInputField = fileInput;
  fileInputField.value = null;

  if (fileTypeErrorHandler) {
    fileTypeErrorHandler();
  } else {
    const errorMessage = `Invalid file format (${fileType}). Only ${permittedFileTypes.join(
      ', ',
    )} files are permitted.`;
    addErrorMessage(fileInput, errorMessage);
  }
}

/**
 * Validates the file size and handles the error if it's invalid.
 *
 * @external File
 * @see {@link https://developer.mozilla.org/en-US/docs/Web/API/File File}
 *
 * @param {File} file - The file attached by the user
 * @param {string} fileType - The top level file type (i.e. image for image/png)
 * @param {HTMLElement} fileInput - An input form field with type of file
 *
 * @returns {Boolean} Returns false if the file is too big. Otherwise, returns true.
 */
function validateFileSize(file, fileType, fileInput) {
  let { maxFileSizeMb } = fileInput.dataset;

  const { fileSizeErrorHandler } = fileInput.dataset;

  const fileSizeMb = (file.size / (1024 * 1024)).toFixed(2);
  maxFileSizeMb = Number(maxFileSizeMb || MAX_FILE_SIZE_MB[fileType]);

  const isValidFileSize = fileSizeMb <= maxFileSizeMb;

  if (!isValidFileSize) {
    handleFileSizeError(
      fileSizeErrorHandler,
      fileInput,
      fileSizeMb,
      maxFileSizeMb,
    );
  }

  return isValidFileSize;
}

/**
 * Validates the file type and handles the error if it's invalid.
 *
 * @external File
 * @see {@link https://developer.mozilla.org/en-US/docs/Web/API/File File}
 *
 * @param {File} file - The file attached by the user
 * @param {string} fileType - The top level file type (i.e. image for image/png)
 * @param {HTMLElement} fileInput - An input form field with type of file
 *
 * @returns {Boolean} Returns false if the files is an invalid format. Otherwise, returns true.
 */
function validateFileType(file, fileType, fileInput) {
  let { permittedFileTypes } = fileInput.dataset;

  if (permittedFileTypes) {
    permittedFileTypes = JSON.parse(permittedFileTypes);
  }

  permittedFileTypes = permittedFileTypes || PERMITTED_FILE_TYPES;

  const { fileTypeErrorHandler } = fileInput.dataset;

  const isValidFileType = permittedFileTypes.includes(fileType);

  if (!isValidFileType) {
    handleFileTypeError(
      fileTypeErrorHandler,
      fileInput,
      fileType,
      permittedFileTypes,
    );
  }

  return isValidFileType;
}

/**
 * This is the core function to handle validations of uploaded files. It loops
 * through all the uploaded files for the given fileInput and checks the file
 * size and file format. If a file fails a validation, the error is handled.
 *
 * @param {HTMLElement} fileInput - An input form field with type of file
 *
 * @returns {Boolean} Returns false if any files failed validations. Otherwise, returns true.
 */
function validateFileInput(fileInput) {
  let isValidFileInput = true;

  removeErrorMessage(fileInput);
  const files = Array.from(fileInput.files);

  for (let i = 0; i < files.length; i += 1) {
    const file = files[i];
    const fileType = file.type.split('/')[0];

    const isValidFileSize = validateFileSize(file, fileType, fileInput);

    if (!isValidFileSize) {
      isValidFileInput = false;
      break;
    }

    const isValidFileType = validateFileType(file, fileType, fileInput);

    if (!isValidFileType) {
      isValidFileInput = false;
      break;
    }
  }

  return isValidFileInput;
}

/**
 * This function is designed to be exported in areas where we are doing more
 * custom implementations of file uploading using Preact. It can then be used
 * in Preact event handlers. It loops through all file input fields on the DOM
 * and validates any attached files.
 *
 * @returns {Boolean} Returns false if any files failed validations. Otherwise, returns true.
 */
export function validateFileInputs() {
  let validFileInputs = true;
  const fileInputs = document.querySelectorAll('input[type="file"]');

  for (let i = 0; i < fileInputs.length; i += 1) {
    const fileInput = fileInputs[i];
    const validFileInput = validateFileInput(fileInput);

    if (!validFileInput) {
      validFileInputs = false;
      break;
    }
  }

  return validFileInputs;
}

// This is written so that it works automagically by just including this pack
// in a view.
const fileInputs = document.querySelectorAll('input[type="file"]');

fileInputs.forEach(fileInput => {
  fileInput.addEventListener('change', () => {
    validateFileInput(fileInput);
  });
});
