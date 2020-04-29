import { h, Component } from 'preact';
import { Button } from '@crayons';
import { generateMainImage } from '../actions';
import { validateFileInputs } from '../../packs/validateFileInputs';

export class ImageUploader extends Component {
  constructor(props) {
    super(props);
    this.state = {
      insertionImageUrls: [],
      uploadError: false,
      uploadErrorMessage: null,
    };
  };

  handleInsertionImageUpload = e => {
    this.clearUploadError();

    const validFileInputs = validateFileInputs();

    if (validFileInputs) {
      const payload = { image: e.target.files };
      generateMainImage(
        payload,
        this.handleInsertImageUploadSuccess,
        this.onUploadError,
      );
    }
  };

  handleInsertImageUploadSuccess = response => {
    this.setState({
      insertionImageUrls: response.links,
    });
  };

  

  clearUploadError = () => {
    this.setState({
      uploadError: false,
      uploadErrorMessage: null,
    });
  };

  onUploadError = error => {
    this.setState({
      insertionImageUrls: [],
      uploadError: true,
      uploadErrorMessage: error.message,
    });
  };

  execCopyText = () => {
    this.imageMarkdownInput.setSelectionRange(
      0,
      this.imageMarkdownInput.value.length,
    );
    document.execCommand('copy');
    this.imageMarkdownAnnouncer.classList.remove("opacity-0");
  }

  copyText = () => {
    this.imageMarkdownAnnouncer = document.getElementById(
      'image-markdown-copy-link-announcer',
    );
    this.imageMarkdownInput = document.getElementById(
      'image-markdown-copy-link-input',
    );

    const isNativeAndroid =
      navigator.userAgent === 'DEV-Native-android' &&
      typeof AndroidBridge !== "undefined" &&
      AndroidBridge !== null;

    const isClipboardSupported =
      typeof navigator.clipboard !== "undefined" &&
      navigator.clipboard !== null;

    if (isNativeAndroid) {
      AndroidBridge.copyToClipboard(this.imageMarkdownInput.value);
      this.imageMarkdownAnnouncer.classList.remove('opacity-0');
    } else if (isClipboardSupported) {
      navigator.clipboard.writeText(this.imageMarkdownInput.value)
        .then(() => {
          this.imageMarkdownAnnouncer.classList.remove('opacity-0');
        })
        .catch((err) => {
          this.execCopyText();
        });
    } else {
      this.execCopyText();
    }
  };

  linksToMarkdownForm = imageLinks => {
    return imageLinks.map(imageLink => `![Alt Text](${imageLink})`).join('\n');
  };

  render() {
    const { insertionImageUrls, uploadError, uploadErrorMessage } = this.state;
    const IconCopy = () => (
      <svg width="24" height="24" viewBox="0 0 24 24" className="crayons-icon" xmlns="http://www.w3.org/2000/svg">
        <path d="M7 6V3a1 1 0 011-1h12a1 1 0 011 1v14a1 1 0 01-1 1h-3v3c0 .552-.45 1-1.007 1H4.007A1 1 0 013 21l.003-14c0-.552.45-1 1.007-1H7zm2 0h8v10h2V4H9v2zm-2 5v2h6v-2H7zm0 4v2h6v-2H7z"/>
      </svg>
    );
    const IconImage = () => (
      <svg
        width="24"
        height="24"
        viewBox="0 0 24 24"
        className="crayons-icon"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path d="M20 5H4v14l9.292-9.294a1 1 0 011.414 0L20 15.01V5zM2 3.993A1 1 0 012.992 3h18.016c.548 0 .992.445.992.993v16.014a1 1 0 01-.992.993H2.992A.993.993 0 012 20.007V3.993zM8 11a2 2 0 110-4 2 2 0 010 4z" />
      </svg>
    );

    return (
      <div className="flex items-center">
        <Button
          className="mr-2"
          variant="ghost"
          contentType="icon-left"
          icon={IconImage}
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
          />
        </Button>

        {insertionImageUrls.length > 0 && (
          <clipboard-copy
            onClick={this.copyText}
            for="image-markdown-copy-link-input"
            aria-live="polite"
            className="flex items-center flex-1"
            aria-controls="image-markdown-copy-link-announcer"
          >
            <input
              type="text"
              className="crayons-textfield mr-2"
              id="image-markdown-copy-link-input"
              readOnly="true"
              value={this.linksToMarkdownForm(insertionImageUrls)}
            />
            <Button variant="ghost" contentType="icon" icon={IconCopy} />
            <span id="image-markdown-copy-link-announcer" role="alert" className="fs-s opacity-0">
              Copied!
            </span>
          </clipboard-copy>
        )}

        {uploadError && (
          <span className="color-accent-danger">{uploadErrorMessage}</span>
        )}
      </div>
    );
  }
}

ImageUploader.displayName = 'ImageUploader';
