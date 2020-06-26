import { h, Component } from 'preact';
import { generateMainImage } from '../actions';
import { validateFileInputs } from '../../packs/validateFileInputs';
import { ClipboardButton } from './ClipboardButton';
import { Button } from '@crayons';

function isNativeAndroid() {
  return (
    navigator.userAgent === 'DEV-Native-android' &&
    typeof AndroidBridge !== 'undefined' &&
    AndroidBridge !== null
  );
}

function isClipboardSupported() {
  return (
    typeof navigator.clipboard !== 'undefined' && navigator.clipboard !== null
  );
}

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

export class ImageUploader extends Component {
  state = {
    insertionImageUrls: [],
    uploadError: false,
    uploadErrorMessage: null,
    showImageCopiedMessage: false,
  };

  onUploadError = (error) => {
    this.setState({
      insertionImageUrls: [],
      uploadError: true,
      uploadErrorMessage: error.message,
    });
  };

  copyText = () => {
    this.imageMarkdownInput = document.getElementById(
      'image-markdown-copy-link-input',
    );

    if (isNativeAndroid()) {
      AndroidBridge.copyToClipboard(this.imageMarkdownInput.value);
      this.setState({ showImageCopiedMessage: true });
    } else if (isClipboardSupported()) {
      navigator.clipboard
        .writeText(this.imageMarkdownInput.value)
        .then(() => {
          this.setState({ showImageCopiedMessage: true });
        })
        .catch((_err) => {
          this.execCopyText();
        });
    } else {
      this.execCopyText();
    }
  };

  handleInsertionImageUpload = (e) => {
    const { files } = e.target;

    this.clearUploadError();
    const validFileInputs = validateFileInputs();

    if (validFileInputs && files.length > 0) {
      const payload = { image: files };

      this.setState({ showImageCopiedMessage: false });

      generateMainImage(
        payload,
        this.handleInsertImageUploadSuccess,
        this.onUploadError,
      );
    }
  };

  handleInsertImageUploadSuccess = (response) => {
    this.setState({
      insertionImageUrls: response.links,
    });
  };

  execCopyText() {
    this.imageMarkdownInput.setSelectionRange(
      0,
      this.imageMarkdownInput.value.length,
    );
    document.execCommand('copy');
    this.setState({ showImageCopiedMessage: true });
  }

  clearUploadError() {
    this.setState({
      uploadError: false,
      uploadErrorMessage: null,
    });
  }

  render() {
    const {
      insertionImageUrls,
      uploadError,
      uploadErrorMessage,
      showImageCopiedMessage,
    } = this.state;

    return (
      <div className="flex items-center">
        <Button
          className="mr-2 fw-normal"
          variant="ghost"
          contentType="icon-left"
          icon={ImageIcon}
          tabIndex="-1"
        >
          Upload image
          <input
            type="file"
            id="image-upload-field"
            onChange={this.handleInsertionImageUpload}
            className="w-100 h-100 absolute left-0 right-0 top-0 bottom-0 overflow-hidden opacity-0 cursor-pointer"
            multiple
            accept="image/*"
            data-max-file-size-mb="25"
            tabIndex="-1"
            aria-label="Upload an image"
          />
        </Button>

        {insertionImageUrls.length > 0 && (
          <ClipboardButton
            onCopy={this.copyText}
            imageUrls={insertionImageUrls}
            showCopyMessage={showImageCopiedMessage}
          />
        )}

        {uploadError && (
          <span className="color-accent-danger">{uploadErrorMessage}</span>
        )}
      </div>
    );
  }
}

ImageUploader.displayName = 'ImageUploader';
