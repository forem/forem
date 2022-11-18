import { addSnackbarItem } from '../Snackbar';

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
 * The maximum length of the file name to prevent errors on the backend when a
 * file name is too long.
 *
 * @constant {number}
 */
const MAX_FILE_NAME_LENGTH = 250;

/**
 * Adds error messages in the form of a div with red text.
 *
 * @param {string} msg - The error message to be displayed to the user
 *
 * @returns {HTMLElement} The error element that was added to the DOM
 */
function addErrorMessage(msg) {
  if (top.addSnackbarItem) {
    // The Comment editor's context (MarkdownToolbar component) doesn't have
    // access to the Snackbar element in the DOM, so it needs to use `top`
    top.addSnackbarItem({
      message: msg,
      addCloseButton: true,
    });
  } else {
    // The Post editor (Toolbar component) doesn't have access to
    // `top.addSnackbarItem` so we need to check to ensure if it's undefined
    addSnackbarItem({
      message: msg,
      addCloseButton: true,
    });
  }
}

/**
 * Handles errors for files that are too large.
 *
 * @param {object} fileSizeErrorHandler - A custom function to be ran after the default error handling
 * @param {number} fileSizeMb - The size of the file in MB
 * @param {?number} maxFileSizeMb - The max file size limit in MB
 */
function handleFileSizeError(fileSizeErrorHandler, fileSizeMb, maxFileSizeMb) {
  if (fileSizeErrorHandler) {
    fileSizeErrorHandler();
  } else {
    let errorMessage = `File size too large (${fileSizeMb} MB).`;

    // If a user uploads a file type that we haven't defined a max size limit for then maxFileSizeMb
    // could be NaN
    if (maxFileSizeMb >= 0) {
      errorMessage += ` The limit is ${maxFileSizeMb} MB.`;
    }

    addErrorMessage(errorMessage);
  }
}

/**
 * Handles errors for files that are not a valid format.
 *
 * @param {object} fileSizeErrorHandler - A custom function to be ran after the default error handling
 * @param {string} fileType - The top level file type (i.e. image for image/png)
 * @param {string[]} permittedFileTypes - The top level file types (i.e. image for image/png) that are permitted
 */
function handleFileTypeError(
  fileTypeErrorHandler,
  fileType,
  permittedFileTypes,
) {
  if (fileTypeErrorHandler) {
    fileTypeErrorHandler();
  } else {
    const fileTypeBracketed =
      fileType && fileType.length !== 0 ? ` (${fileType})` : '';
    const errorMessage = `Invalid file format${fileTypeBracketed}. Only ${permittedFileTypes.join(
      ', ',
    )} files are permitted.`;
    addErrorMessage(errorMessage);
  }
}

/**
 * Handles errors for files with names that are too long.
 *
 * @param {object} fileNameLengthErrorHandler - A custom function to be ran after the default error handling
 * @param {number} maxFileNameLength - The max number of characters permitted for a file name
 */
function handleFileNameLengthError(
  fileNameLengthErrorHandler,
  maxFileNameLength,
) {
  if (fileNameLengthErrorHandler) {
    fileNameLengthErrorHandler();
  } else {
    const errorMessage = `File name is too long. It can't be longer than ${maxFileNameLength} characters.`;
    addErrorMessage(errorMessage);
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
    handleFileSizeError(fileSizeErrorHandler, fileSizeMb, maxFileSizeMb);
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
    handleFileTypeError(fileTypeErrorHandler, fileType, permittedFileTypes);
  }

  return isValidFileType;
}

/**
 * Validates the length of the file name and handles the error if it's invalid.
 *
 * @external File
 * @see {@link https://developer.mozilla.org/en-US/docs/Web/API/File File}
 *
 * @param {File} file - The file attached by the user
 * @param {HTMLElement} fileInput - An input form field with type of file
 *
 * @returns {Boolean} Returns false if the file name is too long. Otherwise, returns true.
 */
function validateFileNameLength(file, fileInput) {
  let { maxFileNameLength } = fileInput.dataset;

  maxFileNameLength = Number(maxFileNameLength || MAX_FILE_NAME_LENGTH);

  const { fileNameLengthErrorHandler } = fileInput.dataset;

  const isValidFileNameLength = file.name.length <= maxFileNameLength;

  if (!isValidFileNameLength) {
    handleFileNameLengthError(fileNameLengthErrorHandler, maxFileNameLength);
  }

  return isValidFileNameLength;
}

/**
 * This is the core function to handle validations of uploaded files. It loops
 * through all the uploaded files for the given fileInput and checks the file
 * size, file format, and file name length. If a file fails a validation, the
 * error is handled.
 *
 * @param {HTMLElement} fileInput - An input form field with type of file
 *
 * @returns {Boolean} Returns false if any files failed validations. Otherwise, returns true.
 */
function validateFileInput(fileInput) {
  let isValidFileInput = true;

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

    const isValidFileNameLength = validateFileNameLength(file, fileInput);

    if (!isValidFileNameLength) {
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

fileInputs.forEach((fileInput) => {
  fileInput.addEventListener('change', () => {
    validateFileInput(fileInput);
  });
});
