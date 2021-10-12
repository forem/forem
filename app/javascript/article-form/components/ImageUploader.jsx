/* global Runtime */

import { Fragment, h } from 'preact';
import { useReducer, useEffect, useState } from 'preact/hooks';
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
    aria-hidden="true"
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
        uploadingErrorMessage: null,
        uploadingImage: true,
        insertionImageUrls: [],
      };

    case 'upload_error':
      return {
        ...state,
        insertionImageUrls: [],
        uploadErrorMessage: payload.errorMessage,
        uploadingImage: false,
      };

    case 'upload_image_success':
      return {
        ...state,
        insertionImageUrls: payload.insertionImageUrls,
        uploadingImage: false,
        uploadingErrorMessage: null,
      };

    default:
      return state;
  }
}

function initNativeImagePicker(e) {
  e?.preventDefault();
  window.webkit.messageHandlers.imageUpload.postMessage({
    id: 'native-image-upload-message',
  });
}

/**
 * Button which triggers native iOS image upload behavior in V1 Editor UI
 *
 * @param {object} props
 * @param {boolean} props.uploadingImage Is an image currently being uploaded
 * @param {function} props.handleNativeMessage Callback to handle iOS native message
 */
const NativeIosV1ImageUpload = ({ uploadingImage, handleNativeMessage }) => (
  <Fragment>
    {!uploadingImage && (
      <Button
        aria-label="Upload an image"
        className="mr-2 fw-normal"
        variant="ghost"
        contentType="icon-left"
        icon={ImageIcon}
        onClick={initNativeImagePicker}
      >
        Upload image
      </Button>
    )}
    <input
      type="hidden"
      id="native-image-upload-message"
      value=""
      onChange={handleNativeMessage}
    />
  </Fragment>
);

/**
 * The V2 editor uses a toolbar button press to trigger a visually hidden file input.
 *
 * @param {object} props
 * @param {object} props.buttonProps Any props to be added to the trigger button
 * @param {function} props.handleInsertionImageUpload Callback to handle image upload
 * @param {boolean} props.uploadingImage Is an image currently being uploaded
 * @param {boolean} props.useNativeUpload Should iOS native upload functionality be used
 * @param {function} props.handleNativeMessage Callback for iOS native upload message handling
 * @param {string} props.uploadErrorMessage Error message to be displayed
 *
 */
const V2EditorImageUpload = ({
  buttonProps,
  handleInsertionImageUpload,
  uploadingImage,
  useNativeUpload,
  handleNativeMessage,
  uploadErrorMessage,
}) => {
  useEffect(() => {
    if (uploadErrorMessage) {
      addSnackbarItem({
        message: uploadErrorMessage,
        addCloseButton: true,
      });
    }
  }, [uploadErrorMessage]);

  const { tooltip: actionTooltip } = buttonProps;
  return (
    <Fragment>
      {useNativeUpload ? (
        <input
          type="hidden"
          id="native-image-upload-message"
          value=""
          onChange={handleNativeMessage}
        />
      ) : (
        <input
          type="file"
          tabindex="-1"
          aria-label="Upload image"
          id="image-upload-field"
          onChange={handleInsertionImageUpload}
          className="screen-reader-only"
          accept="image/*"
          data-max-file-size-mb="25"
        />
      )}

      <Button
        {...buttonProps}
        icon={uploadingImage ? Spinner : ImageIcon}
        onClick={() => {
          if (useNativeUpload) {
            initNativeImagePicker();
          } else {
            document.getElementById('image-upload-field').click();
          }
        }}
        aria-label="Upload image"
        tooltip={uploadingImage ? 'Uploading' : actionTooltip}
      />
    </Fragment>
  );
};

/**
 * The V1 Editor uses a more detailed image upload UI, displaying errors and markdown text inline
 *
 * @param {object} props
 * @param {boolean} props.uploadingImage Is an image currently being uploaded
 * @param {boolean} props.useNativeUpload Should iOS native upload functionality be used
 * @param {function} props.handleNativeMessage Callback for iOS native upload message handling
 * @param {function} props.handleInsertionImageUpload Callback to handle image upload
 * @param {string[]} props.insertionImageUrls URLs of successfully uploaded images
 * @param {string} props.uploadErrorMessage Error message to be displayed
 *
 * @returns
 */
const V1EditorImageUpload = ({
  uploadingImage,
  useNativeUpload,
  handleNativeMessage,
  handleInsertionImageUpload,
  insertionImageUrls,
  uploadErrorMessage,
}) => {
  const [showCopiedImageText, setShowCopiedImageText] = useState(false);

  useEffect(() => {
    if (uploadingImage) {
      setShowCopiedImageText(false);
    }
  }, [uploadingImage]);

  const copyText = () => {
    const imageMarkdownInput = document.getElementById(
      'image-markdown-copy-link-input',
    );

    Runtime.copyToClipboard(imageMarkdownInput.value)
      .then(() => {
        setShowCopiedImageText(true);
      })
      .catch((error) => {
        addSnackbarItem({
          message: error,
          addCloseButton: true,
        });
        Honeybadger.notify(error);
      });
  };
  return (
    <div className="flex items-center">
      {uploadingImage && (
        <span class="lh-base pl-3 border-0 py-2 inline-block">
          <Spinner /> Uploading...
        </span>
      )}

      {useNativeUpload ? (
        <NativeIosV1ImageUpload
          uploadingImage={uploadingImage}
          handleNativeMessage={handleNativeMessage}
        />
      ) : uploadingImage ? null : (
        <Fragment>
          <label className="cursor-pointer crayons-btn crayons-btn--ghost">
            <ImageIcon /> Upload image
            <input
              type="file"
              id="image-upload-field"
              onChange={handleInsertionImageUpload}
              className="screen-reader-only"
              multiple
              accept="image/*"
              data-max-file-size-mb="25"
            />
          </label>
        </Fragment>
      )}

      {insertionImageUrls.length > 0 && (
        <ClipboardButton
          onCopy={copyText}
          imageUrls={insertionImageUrls}
          showCopyMessage={showCopiedImageText}
        />
      )}

      {uploadErrorMessage ? (
        <span className="color-accent-danger">{uploadErrorMessage}</span>
      ) : null}
    </div>
  );
};

/**
 * Image Uploader feature for editor forms
 *
 * @param {object} props
 * @param {string} props.editorVersion The current editor version being used
 * @param {object} props.buttonProps Any additional props to be added to upload image button (v2 editor only)
 * @param {function} props.onImageUploadStart Callback for when image upload begins
 * @param {function} props.onImageUploadSuccess Callback for when image upload succeeds
 * @param {function} props.onImageUploadError Callback for when image upload fails
 *
 */
export const ImageUploader = ({
  editorVersion = 'v2',
  buttonProps = {},
  onImageUploadStart,
  onImageUploadSuccess,
  onImageUploadError,
}) => {
  const [state, dispatch] = useReducer(imageUploaderReducer, {
    insertionImageUrls: [],
    uploadErrorMessage: null,
    uploadingImage: false,
  });

  const { uploadingImage, uploadErrorMessage, insertionImageUrls } = state;

  function onUploadError(error) {
    onImageUploadError?.();
    dispatch({
      type: 'upload_error',
      payload: { errorMessage: error.message },
    });
  }

  function handleInsertionImageUpload(e) {
    const { files } = e.target;

    if (files.length > 0 && validateFileInputs()) {
      const payload = { image: files };
      dispatch({
        type: 'uploading_image',
      });

      onImageUploadStart?.();
      generateMainImage(payload, handleInsertImageUploadSuccess, onUploadError);
    }
  }

  function handleInsertImageUploadSuccess(response) {
    dispatch({
      type: 'upload_image_success',
      payload: { insertionImageUrls: response.links },
    });

    onImageUploadSuccess?.(`![Image description](${response.links})`);
  }

  function handleNativeMessage(e) {
    const message = JSON.parse(e.target.value);

    switch (message.action) {
      case 'uploading':
        onImageUploadStart?.();
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
        onImageUploadSuccess?.(`![Image description](${message.link})`);
        dispatch({
          type: 'upload_image_success',
          payload: { insertionImageUrls: [message.link] },
        });
        break;
    }
  }

  // When the component is rendered in an environment that supports a native
  // image picker, we want to use the native UX rather than standard file upload
  const useNativeUpload = Runtime.isNativeIOS('imageUpload');

  if (editorVersion === 'v2') {
    return (
      <V2EditorImageUpload
        buttonProps={buttonProps}
        uploadingImage={uploadingImage}
        handleInsertionImageUpload={handleInsertionImageUpload}
        useNativeUpload={useNativeUpload}
        handleNativeMessage={handleNativeMessage}
        uploadErrorMessage={uploadErrorMessage}
      />
    );
  }

  return (
    <V1EditorImageUpload
      uploadingImage={uploadingImage}
      useNativeUpload={useNativeUpload}
      handleNativeMessage={handleNativeMessage}
      handleInsertionImageUpload={handleInsertionImageUpload}
      insertionImageUrls={insertionImageUrls}
      uploadErrorMessage={uploadErrorMessage}
    />
  );
};

ImageUploader.displayName = 'ImageUploader';
