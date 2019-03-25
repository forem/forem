import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { generateMainImage } from '../actions';

export default class ImageManagement extends Component {
  constructor(props) {
    super(props);
    this.state = {
      insertionImageUrl: null,
      uploadError: false,
      uploadErrorMessage: null,
    };
  }

  handleMainImageUpload = e => {
    e.preventDefault();

    this.clearUploadError();

    const payload = { image: e.target.files, wrap_cloudinary: true };
    const { onMainImageUrlChange } = this.props;

    generateMainImage(payload, onMainImageUrlChange, this.onUploadError);
  };

  handleInsertionImageUpload = e => {
    this.clearUploadError();

    const payload = { image: e.target.files };
    generateMainImage(
      payload,
      this.handleInsertImageUploadSuccess,
      this.onUploadError,
    );
  };

  handleInsertImageUploadSuccess = response => {
    this.setState({
      insertionImageUrl: response.link,
    });
  };

  triggerMainImageRemoval = e => {
    e.preventDefault();

    const { onMainImageUrlChange } = this.props;

    onMainImageUrlChange({
      link: null,
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
      insertionImageUrl: null,
      uploadError: true,
      uploadErrorMessage: error.message,
    });
  };

  render() {
    const { onExit, mainImageUrl } = this.props;
    const { insertionImageUrl, uploadError, uploadErrorMessage } = this.state;
    let mainImageArea;

    if (mainImageUrl) {
      mainImageArea = (
        <div>
          <img src={mainImageUrl} alt="main" />

          <button type="button" onClick={this.triggerMainImageRemoval}>
            Remove Cover Image
          </button>
        </div>
      );
    } else {
      mainImageArea = (
        <div>
          <input type="file" onChange={this.handleMainImageUpload} />
        </div>
      );
    }

    let insertionImageArea;
    if (insertionImageUrl) {
      insertionImageArea = (
        <div>
          <h3>Markdown Image:</h3>
          <input type="text" value={`![](${insertionImageUrl})`} />
          <h3>Direct URL:</h3>
          <input type="text" value={insertionImageUrl} />
        </div>
      );
    } else {
      insertionImageArea = (
        <div>
          <input type="file" onChange={this.handleInsertionImageUpload} />
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
        <h2>Cover Image</h2>
        {mainImageArea}
        <h2>Body Images</h2>
        {insertionImageArea}
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
  mainImageUrl: PropTypes.string,
};

ImageManagement.defaultProps = {
  mainImageUrl: '',
};
