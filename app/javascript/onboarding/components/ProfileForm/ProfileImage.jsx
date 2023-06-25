import { h, Fragment } from 'preact';
import { useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { generateMainImage } from '../actions';
import { validateFileInputs } from '../../../packs/validateFileInputs';
import { Spinner } from '@crayons/Spinner/Spinner';

const StandardImageUpload = ({ handleImageUpload, isUploadingImage }) =>
  isUploadingImage ? null : (
    <Fragment>
      <label className="cursor-pointer crayons-btn crayons-btn--secondary">
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

    if (validateFileInputs()) {
      const { files: image } = event.dataTransfer || event.target;
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

  const clearUploadError = () => {
    setUploadError(false);
    setUploadErrorMessage(null);
  };

  const onUploadError = (error) => {
    setUploadingImage(false);
    setUploadError(true);
    setUploadErrorMessage(error.message);
  };

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
          <StandardImageUpload
            isUploadingImage={uploadingImage}
            handleImageUpload={handleMainImageUpload}
          />
        </Fragment>

        {uploadError && (
          <p className="onboarding-profile-upload-error">
            {uploadErrorMessage}
          </p>
        )}
      </div>
    </div>
  );
};

ProfileImage.propTypes = {
  mainImage: PropTypes.string,
  onMainImageUrlChange: PropTypes.func.isRequired,
};

ProfileImage.displayName = 'ProfileImage';
