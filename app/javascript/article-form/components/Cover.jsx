import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { Button } from '@crayons';
import { generateMainImage } from '../actions';
import { validateFileInputs } from '../../packs/validateFileInputs';

export class Cover extends Component {
  constructor(props) {
    super(props);
    this.state = {
      uploadError: false,
      uploadErrorMessage: null,
    };
  };

  handleMainImageUpload = (e) => {
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

  clearUploadError = () => {
    this.setState({
      uploadError: false,
      uploadErrorMessage: null,
    });
  };

  onUploadError = error => {
    this.setState({
      uploadError: true,
      uploadErrorMessage: error.message,
    });
  };

  triggerMainImageRemoval = e => {
    e.preventDefault();

    const { onMainImageUrlChange } = this.props;

    onMainImageUrlChange({
      links: [],
    });
  };

  render () {
    const { mainImage } = this.props;
    const { uploadError, uploadErrorMessage } = this.state;
    const uploadLabel = mainImage ? 'Change the cover' : 'Add a cover photo';
    return (
      <div className="crayons-article-form__cover" role="presentation">
        {mainImage && (
          <img
            src={mainImage}
            className="crayons-article-form__cover__image"
            width="200"
            height="100"
            alt=""
          />
        )}
        <label className="crayons-btn crayons-btn--outlined mr-2">
          {uploadLabel}
          <input
            type="file"
            onChange={this.handleMainImageUpload}
            accept="image/*"
            className="w-0 h-0 absolute overflow-hidden z-negative opacity-0"
            data-max-file-size-mb="25"
          />
        </label>
        {mainImage && (
          <Button variant="ghost-danger" onClick={this.triggerMainImageRemoval}>
            Remove
          </Button>
        )}
        {uploadError && (
          <span className="articleform__uploaderror">{uploadErrorMessage}</span>
        )}
      </div>
    );
  }
};

Cover.propTypes = {
  mainImage: PropTypes.string.isRequired,
  onMainImageUrlChange: PropTypes.func.isRequired,
};

Cover.displayName = 'Cover';
