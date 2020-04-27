import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { generateMainImage } from '../actions';
import { validateFileInputs } from '../../packs/validateFileInputs';

export class Cover extends Component {
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
    return (
      <div className="crayons-article-form__cover" role="presentation">
        {/* <button className="crayons-btn crayons-btn--secondary" type="button">Add a cover image</button> */}
        {mainImage && (
          <div>
            <img
              src={mainImage}
              className="crayons-article-form__cover__image"
              width="200"
              height="100"
              alt=""
            />
            <button type="button" onClick={this.triggerMainImageRemoval}>
              Remove Cover Image
            </button>
          </div>
        )}
        <input
          type="file"
          onChange={this.handleMainImageUpload}
          accept="image/*"
          data-max-file-size-mb="25"
        />
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
