/* global Runtime */

import { h, Component, Fragment } from 'preact';
import PropTypes from 'prop-types';
import { addSnackbarItem } from '../../Snackbar';
import { generateMainImage } from '../actions';
import { validateFileInputs } from '../../packs/validateFileInputs';
import { onDragOver, onDragExit } from './dragAndDropHelpers';
import { Button } from '@crayons';
import { Spinner } from '@crayons/Spinner/Spinner';
import { DragAndDropZone } from '@utilities/dragAndDrop';

const NativeIosImageUpload = ({
  extraProps,
  uploadLabel,
  isUploadingImage,
}) => (
  <Fragment>
    {isUploadingImage ? null : (
      <Button
        variant="outlined"
        className="mr-2 whitespace-nowrap"
        {...extraProps}
      >
        {uploadLabel}
      </Button>
    )}
  </Fragment>
);

const StandardImageUpload = ({
  uploadLabel,
  handleImageUpload,
  isUploadingImage,
}) =>
  isUploadingImage ? null : (
    <Fragment>
      <label className="cursor-pointer crayons-btn crayons-btn--outlined">
        {uploadLabel}
        <input
          id="cover-image-input"
          type="file"
          onChange={handleImageUpload}
          accept="image/*"
          className="screen-reader-only"
          data-max-file-size-mb="25"
        />
      </label>
    </Fragment>
  );

export class ArticleCoverImage extends Component {
  state = {
    uploadError: false,
    uploadErrorMessage: null,
    uploadingImage: false,
  };

  onImageUploadSuccess = (...args) => {
    this.props.onMainImageUrlChange(...args);
    this.setState({ uploadingImage: false });
  };

  handleMainImageUpload = (event) => {
    event.preventDefault();

    this.setState({ uploadingImage: true });
    this.clearUploadError();

    if (validateFileInputs()) {
      const { files: image } = event.dataTransfer || event.target;
      const payload = { image };

      generateMainImage({
        payload,
        successCb: this.onImageUploadSuccess,
        failureCb: this.onUploadError,
      });
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
      uploadingImage: false,
      uploadError: true,
      uploadErrorMessage: error.message,
    });
  };

  useNativeUpload = () => {
    // This namespace is not implemented in the native side. This allows us to
    // deploy our refactor and wait until our iOS app is approved by AppStore
    // review. The old web implementation will be the fallback until then.
    return Runtime.isNativeIOS('imageUpload_disabled');
  };

  initNativeImagePicker = (e) => {
    e.preventDefault();
    window.ForemMobile?.injectNativeMessage('coverUpload', {
      action: 'coverImageUpload',
      ratio: `${100.0 / 42.0}`,
    });
  };

  handleNativeMessage = (e) => {
    const message = JSON.parse(e.detail);
    if (message.namespace !== 'coverUpload') {
      return;
    }

    /* eslint-disable no-case-declarations */
    switch (message.action) {
      case 'uploading':
        this.setState({ uploadingImage: true });
        this.clearUploadError();
        break;
      case 'error':
        this.setState({
          uploadingImage: false,
          uploadError: true,
          uploadErrorMessage: message.error,
        });
        break;
      case 'success':
        const { onMainImageUrlChange } = this.props;
        onMainImageUrlChange({
          links: [message.link],
        });
        this.setState({ uploadingImage: false });
        break;
    }
    /* eslint-enable no-case-declarations */
  };

  triggerMainImageRemoval = (e) => {
    e.preventDefault();
    const { onMainImageUrlChange } = this.props;
    onMainImageUrlChange({
      links: [null],
    });
  };

  onDropImage = (event) => {
    onDragExit(event);

    if (event.dataTransfer.files.length > 1) {
      addSnackbarItem({
        message: 'Only one image can be dropped at a time.',
        addCloseButton: true,
      });
      return;
    }

    this.handleMainImageUpload(event);
  };

  render() {
    const { mainImage } = this.props;
    const { uploadError, uploadErrorMessage, uploadingImage } = this.state;
    const uploadLabel = mainImage ? 'Change' : 'Add a cover image';

    // When the component is rendered in an environment that supports a native
    // image picker for image upload we want to add the aria-label attr and the
    // onClick event to the UI button. This event will kick off the native UX.
    // The props are unwrapped (using spread operator) in the button below
    const extraProps = this.useNativeUpload()
      ? {
          onClick: this.initNativeImagePicker,
          'aria-label': 'Upload cover image',
        }
      : {};

    // Native Bridge messages come through ForemMobile events
    document.addEventListener('ForemMobile', this.handleNativeMessage);

    return (
      <DragAndDropZone
        onDragOver={onDragOver}
        onDragExit={onDragExit}
        onDrop={this.onDropImage}
      >
        <div className="crayons-article-form__cover" role="presentation">
          {!uploadingImage && mainImage && (
            <img
              src={mainImage}
              className="crayons-article-form__cover__image"
              width="250"
              height="105"
              alt="Post cover"
            />
          )}
          <div className="flex items-center">
            {uploadingImage && (
              <span class="lh-base pl-1 border-0 py-2 inline-block">
                <Spinner /> Uploading...
              </span>
            )}

            <Fragment>
              {this.useNativeUpload() ? (
                <NativeIosImageUpload
                  isUploadingImage={uploadingImage}
                  extraProps={extraProps}
                  uploadLabel={uploadLabel}
                />
              ) : (
                <StandardImageUpload
                  isUploadingImage={uploadingImage}
                  uploadLabel={uploadLabel}
                  handleImageUpload={this.handleMainImageUpload}
                />
              )}

              {mainImage && !uploadingImage && (
                <Button
                  variant="ghost-danger"
                  onClick={this.triggerMainImageRemoval}
                >
                  Remove
                </Button>
              )}
            </Fragment>
          </div>
          {uploadError && (
            <p className="articleform__uploaderror">{uploadErrorMessage}</p>
          )}
        </div>
      </DragAndDropZone>
    );
  }
}

ArticleCoverImage.propTypes = {
  mainImage: PropTypes.string,
  onMainImageUrlChange: PropTypes.func.isRequired,
};

ArticleCoverImage.displayName = 'ArticleCoverImage';
