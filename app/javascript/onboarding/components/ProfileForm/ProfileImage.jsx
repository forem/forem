import { h, Fragment } from 'preact';
import { useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { generateMainImage } from '../actions';
import { validateFileInputs } from '../../../packs/validateFileInputs';
import { Button } from '@crayons';
import { Spinner } from '@crayons/Spinner/Spinner';
import { isNativeIOS } from '@utilities/runtime';

const NativeIosImageUpload = ({ extraProps, isUploadingImage }) => (
  <Fragment>
    {isUploadingImage ? null : (
      <Button
        variant="outlined"
        className="mr-2 whitespace-nowrap"
        {...extraProps}
      >
        Edit profile image
      </Button>
    )}
  </Fragment>
);

const StandardImageUpload = ({ handleImageUpload, isUploadingImage }) =>
  isUploadingImage ? null : (
    <Fragment>
      <label className="cursor-pointer crayons-btn crayons-btn--outlined">
        Edit profile image
        <input
          data-testid="profile-image-input"
          id="profile-image-input"
          type="file"
          onChange={handleImageUpload}
          accept="image/*"
          className="screen-reader-only"
          data-max-file-size-mb="25"
        />
      </label>
    </Fragment>
  );

export const ProfileImage = ({
  onMainImageUrlChange,
  mainImage,
  userId,
  name,
}) => {
  const [uploadError, setUploadError] = useState(false);
  const [uploadErrorMessage, setUploadErrorMessage] = useState(null);
  const [uploadingImage, setUploadingImage] = useState(false);

  const onImageUploadSuccess = (url) => {
    onMainImageUrlChange(url);
    setUploadingImage(false);
  };

  const handleMainImageUpload = (event) => {
    event.preventDefault();

    setUploadingImage(true);
    clearUploadError();

    const { files: image } = event.dataTransfer || event.target;

    const img = new Image();
    img.onload = function () {
      if (this.width > 4096 || this.height > 4096) {
        setUploadingImage(false);
        setUploadError(true);
        setUploadErrorMessage(
          'Image size should be less than or equal to 4096x4096.',
        );
      } else if (validateFileInputs()) {
        const payload = { image, userId };

        generateMainImage({
          payload,
          successCb: onImageUploadSuccess,
          failureCb: onUploadError,
        });
      } else {
        setUploadingImage(false);
      }
    };
    img.src = URL.createObjectURL(image[0]);
  };

  const clearUploadError = () => {
    setUploadError(false);
    setUploadErrorMessage(null);
  };

  const onUploadError = (error) => {
    setUploadingImage(false);
    setUploadError(true);
    setUploadErrorMessage(error.message);
  };

  const useNativeUpload = () => {
    return isNativeIOS('imageUpload');
  };

  const initNativeImagePicker = (e) => {
    e.preventDefault();
    window.ForemMobile?.injectNativeMessage('profileUpload', {
      action: 'profileImageUpload',
      ratio: `${100.0 / 100.0}`,
    });
  };

  const handleNativeMessage = (e) => {
    const message = JSON.parse(e.detail);
    if (message.namespace !== 'imageUpload') {
      return;
    }

    /* eslint-disable no-case-declarations */
    switch (message.action) {
      case 'uploading':
        setUploadingImage(true);
        clearUploadError();
        break;
      case 'error':
        setUploadingImage(false);
        setUploadError(true);
        setUploadErrorMessage(message.error);
        break;
      case 'success':
        onMainImageUrlChange({
          links: [message.link],
        });
        setUploadingImage(false);
        break;
    }
    /* eslint-enable no-case-declarations */
  };

  // When the component is rendered in an environment that supports a native
  // image picker for image upload we want to add the aria-label attr and the
  // onClick event to the UI button. This event will kick off the native UX.
  // The props are unwrapped (using spread operator) in the button below
  const extraProps = useNativeUpload()
    ? {
        onClick: initNativeImagePicker,
        'aria-label': 'Upload profile image',
      }
    : {};

  // Native Bridge messages come through ForemMobile events
  document.addEventListener('ForemMobile', handleNativeMessage);

  return (
    <div className="onboarding-profile-details-container" role="presentation">
      {!uploadingImage && mainImage && (
        <img
          className="onboarding-profile-image"
          alt="profile"
          src={mainImage}
        />
      )}
      <div className="onboarding-profile-details-sub-container">
        <h3 className="onboarding-profile-user-name">{name}</h3>
        {uploadingImage && (
          <span class="lh-base pl-1 border-0 py-2 inline-block">
            <Spinner /> Uploading...
          </span>
        )}

        <Fragment>
          {useNativeUpload() ? (
            <NativeIosImageUpload
              isUploadingImage={uploadingImage}
              extraProps={extraProps}
            />
          ) : (
            <StandardImageUpload
              isUploadingImage={uploadingImage}
              handleImageUpload={handleMainImageUpload}
            />
          )}
        </Fragment>
      </div>
      {uploadError && (
        <p className="onboarding-profile-upload-error">{uploadErrorMessage}</p>
      )}
    </div>
  );
};

ProfileImage.propTypes = {
  mainImage: PropTypes.string,
  onMainImageUrlChange: PropTypes.func.isRequired,
};

ProfileImage.displayName = 'ProfileImage';
