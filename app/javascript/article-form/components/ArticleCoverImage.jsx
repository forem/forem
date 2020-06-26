import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { generateMainImage } from '../actions';
import { validateFileInputs } from '../../packs/validateFileInputs';
import { Button } from '@crayons';

export class ArticleCoverImage extends Component {
  constructor(props) {
    super(props);
    this.state = {
      uploadError: false,
      uploadErrorMessage: null,
    };
  }

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

  onUploadError = (error) => {
    this.setState({
      uploadError: true,
      uploadErrorMessage: error.message,
    });
  };

  triggerMainImageRemoval = (e) => {
    e.preventDefault();
    const { onMainImageUrlChange } = this.props;
    onMainImageUrlChange({
      links: [],
    });
  };

  render() {
    const { mainImage } = this.props;
    const { uploadError, uploadErrorMessage } = this.state;
    const uploadLabel = mainImage ? 'Change' : 'Add a cover image';
    return (
      <div className="crayons-article-form__cover" role="presentation">
        {mainImage && (
          <img
            src={mainImage}
            className="crayons-article-form__cover__image"
            width="250"
            height="105"
            alt="Post cover"
          />
        )}
        <div className="flex items-center">
          <Button variant="outlined" className="mr-2 whitespace-nowrap">
            <label htmlFor="cover-image-input">{uploadLabel}</label>
            <input
              id="cover-image-input"
              type="file"
              onChange={this.handleMainImageUpload}
              accept="image/*"
              className="w-100 h-100 absolute left-0 right-0 top-0 bottom-0 overflow-hidden opacity-0 cursor-pointer"
              data-max-file-size-mb="25"
            />
          </Button>
          {mainImage && (
            <Button
              variant="ghost-danger"
              onClick={this.triggerMainImageRemoval}
            >
              Remove
            </Button>
          )}
        </div>
        {uploadError && (
          <p className="articleform__uploaderror">{uploadErrorMessage}</p>
        )}
      </div>
    );
  }
}

ArticleCoverImage.propTypes = {
  mainImage: PropTypes.string.isRequired,
  onMainImageUrlChange: PropTypes.func.isRequired,
};

ArticleCoverImage.displayName = 'ArticleCoverImage';
