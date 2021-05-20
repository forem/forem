/* global Runtime */

import { h } from 'preact';
import { useReducer } from 'preact/hooks';
import { generateMainImage } from '../actions';
import { validateFileInputs } from '../../packs/validateFileInputs';
import { addSnackbarItem } from '../../Snackbar';
import { ClipboardButton } from './ClipboardButton';
import { Button, Spinner } from '@crayons';

const ImageIcon = () => (
  <svg
    width="24"
    height="24"
    viewBox="0 0 24 24"
    className="crayons-icon"
    xmlns="http://www.w3.org/2000/svg"
    role="img"
    aria-labelledby="a17qec5pfhrwzk9w4kg0tp62v27qqu9t"
  >
    <title id="a17qec5pfhrwzk9w4kg0tp62v27qqu9t">Upload image</title>
    <path d="M20 5H4v14l9.292-9.294a1 1 0 011.414 0L20 15.01V5zM2 3.993A1 1 0 012.992 3h18.016c.548 0 .992.445.992.993v16.014a1 1 0 01-.992.993H2.992A.993.993 0 012 20.007V3.993zM8 11a2 2 0 110-4 2 2 0 010 4z" />
  </svg>
);

ImageIcon.displayName = 'ImageIcon';

function imageUploaderReducer(state, action) {
  const { type, payload } = action;

  switch (type) {
    case 'uploading_image':
      return {
        ...state,
        uploadError: false,
        uploadingErrorMessage: null,
        uploadingImage: true,
        insertionImageUrls: [],
        showImageCopiedMessage: false,
      };

    case 'upload_error':
      return {
        ...state,
        insertionImageUrls: [],
        uploadError: true,
        uploadErrorMessage: payload.errorMessage,
        uploadingImage: false,
      };

    case 'show_copied_image_message':
      return {
        ...state,
        showImageCopiedMessage: true,
      };

    case 'upload_image_success':
      return {
        ...state,
        insertionImageUrls: payload.insertionImageUrls,
        uploadingImage: false,
      };

    default:
      return state;
  }
}

export const ImageUploader = () => {
  const [state, dispatch] = useReducer(imageUploaderReducer, {
    insertionImageUrls: [],
    uploadError: false,
    uploadErrorMessage: null,
    showImageCopiedMessage: false,
    uploadingImage: false,
  });

  const {
    uploadingImage,
    showImageCopiedMessage,
    uploadErrorMessage,
    uploadError,
    insertionImageUrls,
  } = state;

  let imageMarkdownInput = null;

  function onUploadError(error) {
    dispatch({
      type: 'upload_error',
      payload: { errorMessage: error.message },
    });
  }

  function copyText() {
    imageMarkdownInput = document.getElementById(
      'image-markdown-copy-link-input',
    );

    Runtime.copyToClipboard(imageMarkdownInput.value)
      .then(() => {
        dispatch({
          type: 'show_copied_image_message',
        });
      })
      .catch((error) => {
        addSnackbarItem({
          message: error,
          addCloseButton: true,
        });
        Honeybadger.notify(error);
      });
  }

  function handleInsertionImageUpload(e) {
    const { files } = e.target;

    if (files.length > 0 && validateFileInputs()) {
      const payload = { image: files };
      dispatch({
        type: 'uploading_image',
      });

      generateMainImage(payload, handleInsertImageUploadSuccess, onUploadError);
    }
  }

  function handleInsertImageUploadSuccess(response) {
    dispatch({
      type: 'upload_image_success',
      payload: { insertionImageUrls: response.links },
    });
  }

  function handleNativeMessage(e) {
    const message = JSON.parse(e.target.value);

    switch (message.action) {
      case 'uploading':
        dispatch({
          type: 'uploading_image',
        });
        break;
      case 'error':
        dispatch({
          type: 'upload_error',
          payload: { errorMessage: message.error },
        });
        break;
      case 'success':
        dispatch({
          type: 'upload_image_success',
          payload: { insertionImageUrls: [message.link] },
        });
        break;
    }
  }

  function initNativeImagePicker(e) {
    e.preventDefault();
    window.webkit.messageHandlers.imageUpload.postMessage({
      id: 'native-image-upload-message',
    });
  }

  // When the component is rendered in an environment that supports a native
  // image picker for image upload we want to add the aria-label attr and the
  // onClick event to the UI button. This event will kick off the native UX.
  // The props are unwrapped (using spread operator) in the button below
  const useNativeUpload = Runtime.isNativeIOS('imageUpload');
  const extraProps = useNativeUpload
    ? { onClick: initNativeImagePicker, 'aria-label': 'Upload an image' }
    : { tabIndex: -1 };

  return (
    <div className="flex items-center">
      {uploadingImage ? (
        <span class="lh-base pl-3 border-0 py-2 inline-block">
          <Spinner /> Uploading...
        </span>
      ) : (
        <Button
          className="mr-2 fw-normal"
          variant="ghost"
          contentType="icon-left"
          icon={ImageIcon}
          {...extraProps}
        >
          Upload image
          {!useNativeUpload && (
            <input
              type="file"
              id="image-upload-field"
              onChange={handleInsertionImageUpload}
              className="w-100 h-100 absolute left-0 right-0 top-0 bottom-0 overflow-hidden opacity-0 cursor-pointer"
              multiple
              accept="image/*"
              data-max-file-size-mb="25"
              aria-label="Upload an image"
            />
          )}
        </Button>
      )}

      {useNativeUpload && (
        <input
          type="hidden"
          id="native-image-upload-message"
          value=""
          onChange={handleNativeMessage}
        />
      )}

      {insertionImageUrls.length > 0 && (
        <ClipboardButton
          onCopy={copyText}
          imageUrls={insertionImageUrls}
          showCopyMessage={showImageCopiedMessage}
        />
      )}

      {uploadError && (
        <span className="color-accent-danger">{uploadErrorMessage}</span>
      )}
    </div>
  );
};

ImageUploader.displayName = 'ImageUploader';
