import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import linkCopyIcon from '../../../assets/images/content-copy.svg';
import { generateMainImage } from '../actions';
import { validateFileInputs } from '../../packs/validateFileInputs';

export default class ImageManagement extends Component {
  constructor(props) {
    super(props);
    this.state = {
      insertionImageUrls: [],
      uploadError: false,
      uploadErrorMessage: null,
    };
  }

  handleMainImageUpload = e => {
    e.preventDefault();

    this.clearUploadError();
    const validFileInputs = validateFileInputs();

    if (validFileInputs) {
      const payload = { image: e.target.files, wrap_cloudinary: true };
      const { onMainImageUrlChange } = this.props;

      generateMainImage(payload, onMainImageUrlChange, this.onUploadError);
    }
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

  triggerMainImageRemoval = e => {
    e.preventDefault();

    const { onMainImageUrlChange } = this.props;

    onMainImageUrlChange({
      links: [],
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
    this.imageMarkdownAnnouncer.hidden = false;
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
      this.imageMarkdownAnnouncer.hidden = false;
    } else if (isClipboardSupported) {
      navigator.clipboard.writeText(this.imageMarkdownInput.value)
        .then(() => {
          this.imageMarkdownAnnouncer.hidden = false;
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

  linksToDirectForm = imageLinks => {
    return imageLinks.join('\n');
  };

  render() {
    const { onExit, mainImage, version } = this.props;
    const { insertionImageUrls, uploadError, uploadErrorMessage } = this.state;
    let mainImageArea;

    if (mainImage) {
      mainImageArea = (
        <div>
          <img src={mainImage} alt="main" />
          <button type="button" onClick={this.triggerMainImageRemoval}>
            Remove Cover Image
          </button>
        </div>
      );
    } else {
      mainImageArea = (
        <div>
          <input
            type="file"
            onChange={this.handleMainImageUpload}
            accept="image/*"
            data-max-file-size-mb="25"
          />
        </div>
      );
    }

    let insertionImageArea;
    if (insertionImageUrls.length > 0) {
      insertionImageArea = (
        <div>
          <h3>Markdown Images:</h3>
          <clipboard-copy
            onClick={this.copyText}
            for="image-markdown-copy-link-input"
            aria-live="polite"
            aria-controls="image-markdown-copy-link-announcer"
          >
            <textarea
              id="image-markdown-copy-link-input"
              value={this.linksToMarkdownForm(insertionImageUrls)}
            />
            <img
              id="image-markdown-copy-icon"
              src={linkCopyIcon}
              alt="Copy to Clipboard"
            />
            <span id="image-markdown-copy-link-announcer" role="alert" hidden>
              Copied to Clipboard
            </span>
          </clipboard-copy>
          <h3>Direct URLs:</h3>
          <textarea
            id="image-direct-copy-link-input"
            value={this.linksToDirectForm(insertionImageUrls)}
          />
        </div>
      );
    } else {
      insertionImageArea = (
        <div>
          <input
            type="file"
            onChange={this.handleInsertionImageUpload}
            multiple
            accept="image/*"
            data-max-file-size-mb="25"
          />
        </div>
      );
    }
    let imageOptions;
    if (version === 'v1') {
      imageOptions = (
        <div>
          <h2>Upload Images</h2>
          {insertionImageArea}
          <div>
            <p>
              <em>
                To add a cover image for the post, add &nbsp;
                <code>cover_image: direct_url_to_image.jpg</code>
                &nbsp; to the frontmatter
              </em>
            </p>
          </div>
        </div>
      );
    } else {
      imageOptions = (
        <div>
          <h2>Cover Image</h2>
          {mainImageArea}
          <h2>Body Images</h2>
          {insertionImageArea}
        </div>
      );
    }
    return (
      <div className="articleform__overlay">
        <button
          type="button"
          className="articleform__exitbutton"
          data-content="exit"
          onClick={onExit}
        >
          ×
        </button>
        {uploadError && (
          <span className="articleform__uploaderror">{uploadErrorMessage}</span>
        )}
        {imageOptions}
        <div>
          <button
            type="button"
            className="articleform__donebutton"
            onClick={onExit}
          >
            Done
          </button>
        </div>
      </div>
    );
  }
}

ImageManagement.propTypes = {
  onExit: PropTypes.func.isRequired,
  onMainImageUrlChange: PropTypes.func.isRequired,
  mainImage: PropTypes.string.isRequired,
  version: PropTypes.string.isRequired,
};
