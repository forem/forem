import { h, Fragment } from 'preact';
import { useState, useMemo } from 'preact/hooks';
import PropTypes from 'prop-types';
import { addSnackbarItem } from '../../Snackbar';
import { generateMainImage, generateAiImage } from '../actions';
import { validateFileInputs } from '../../packs/validateFileInputs';
import { parseVideoUrl, getVideoThumbnail } from '../utilities/videoParser';
import { onDragOver, onDragExit } from './dragAndDropHelpers';
import { CoverVideoLink } from './CoverVideoLink';
import { useMediaQuery } from '@components/useMediaQuery';
import { Button } from '@crayons';
import { Spinner } from '@crayons/Spinner/Spinner';
import { DragAndDropZone } from '@utilities/dragAndDrop';
import { isNativeIOS } from '@utilities/runtime';

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
        style={{minHeight: '2.5rem', display: 'inline-flex', alignItems: 'center'}}
        {...extraProps}
      >
        {uploadLabel}
      </Button>
    )}
  </Fragment>
);

const ImageOptionsModal = ({ onClose, onUpload, onGenerate, aiAvailable }) => {
  return (
    <div className="crayons-modal crayons-modal--m" data-testid="image-options-modal">
      <div 
        className="crayons-modal__box" 
        role="dialog" 
        aria-labelledby="image-options-modal-title"
      >
        <div className="crayons-modal__box__header">
          <h2 id="image-options-modal-title" className="crayons-subtitle-2">Add Cover Image</h2>
          <button 
            onClick={onClose} 
            className="crayons-btn crayons-btn--ghost crayons-btn--icon" 
            aria-label="Close"
            style={{maxWidth: '60px'}}
            type="button"
          >
            <svg width="24" height="24" viewBox="0 0 24 24" class="crayons-icon" xmlns="http://www.w3.org/2000/svg">
              <path d="M12 10.586l4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636z"/>
            </svg>
          </button>
        </div>
        <div className="crayons-modal__box__body">
          <div className="flex flex-col gap-2">
            <Button 
              variant="outlined" 
              onClick={() => {
                onUpload();
                onClose();
              }}
              className="w-100"
              style={{minHeight: '2.5rem'}}
            >
              Upload Image
            </Button>
            {aiAvailable && (
              <Button 
                variant="outlined" 
                onClick={() => {
                  onGenerate();
                  onClose();
                }}
                className="w-100"
                style={{minHeight: '2.5rem'}}
              >
                🍌 Generate Image
              </Button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

ImageOptionsModal.propTypes = {
  onClose: PropTypes.func.isRequired,
  onUpload: PropTypes.func.isRequired,
  onGenerate: PropTypes.func.isRequired,
  aiAvailable: PropTypes.bool.isRequired,
};

const StandardImageUpload = ({
  uploadLabel,
  handleImageUpload,
  isUploadingImage,
  coverImageHeight,
  coverImageCrop,
  onGenerateClick,
  aiAvailable,
  videoSourceUrl,
  onVideoUrlChange,
  isMobile,
  onImageButtonClick,
  showImageOptionsModal,
  onCloseImageOptionsModal,
}) => {
  const showAiButton = aiAvailable;
  
  if (isUploadingImage) return null;

  // Mobile layout: 2 buttons (Image and Video)
  // Hide image button if video is selected
  if (isMobile) {
    return (
      <Fragment>
        {!videoSourceUrl && (
          <Button
            variant="outlined"
            onClick={onImageButtonClick}
            className="mr-2 whitespace-nowrap"
            style={{minHeight: '2.5rem', display: 'inline-flex', alignItems: 'center'}}
            data-testid="mobile-cover-image-btn"
          >
            Add Cover Image
          </Button>
        )}
        <CoverVideoLink
          videoSourceUrl={videoSourceUrl}
          onVideoUrlChange={onVideoUrlChange}
        />
        {showImageOptionsModal && (
          <ImageOptionsModal
            onClose={onCloseImageOptionsModal}
            onUpload={() => {
              // Trigger file input click
              const fileInput = document.getElementById('cover-image-input');
              if (fileInput) {
                fileInput.click();
              }
            }}
            onGenerate={onGenerateClick}
            aiAvailable={aiAvailable}
          />
        )}
        <input
          data-testid="cover-image-input"
          id="cover-image-input"
          type="file"
          onChange={handleImageUpload}
          accept="image/*"
          className="screen-reader-only"
          data-max-file-size-mb="25"
        />
      </Fragment>
    );
  }
  
  // Desktop layout: 3 buttons (Upload, Generate, Video)
  // Hide image buttons if video is selected
  if (videoSourceUrl) {
    return (
      <Fragment>
        <CoverVideoLink
          videoSourceUrl={videoSourceUrl}
          onVideoUrlChange={onVideoUrlChange}
        />
      </Fragment>
    );
  }

  return (
    <Fragment>
      <label className="cursor-pointer crayons-btn crayons-btn--outlined crayons-tooltip__activator mr-2 whitespace-nowrap" style={{minHeight: '2.5rem', display: 'inline-flex', alignItems: 'center'}}>
        {uploadLabel}
        <input
          data-testid="cover-image-input"
          id="cover-image-input"
          type="file"
          onChange={handleImageUpload}
          accept="image/*"
          className="screen-reader-only"
          data-max-file-size-mb="25"
        />
        <span data-testid="tooltip" className="crayons-tooltip__content" style={{minWidth:'190px'}}>
         {coverImageCrop === 'crop' ? `Use a ratio of 1000:${coverImageHeight} ` : 'Minimum 1000px wide '}
         for best results. 
        </span>
      </label>
      {showAiButton && (
        <Button 
          variant="outlined" 
          onClick={onGenerateClick}
          className="mr-2 whitespace-nowrap"
          data-testid="generate-ai-image-btn"
          style={{minHeight: '2.5rem', display: 'inline-flex', alignItems: 'center'}}
        >
          🍌 Generate Image
        </Button>
      )}
      <CoverVideoLink
        videoSourceUrl={videoSourceUrl}
        onVideoUrlChange={onVideoUrlChange}
      />
    </Fragment>
  );
};

const AiImagePromptModal = ({ onClose, onGenerate, isGenerating }) => {
  const [prompt, setPrompt] = useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    if (prompt.trim()) {
      onGenerate(prompt);
    }
  };

  return (
    <div className="crayons-modal crayons-modal--m" data-testid="ai-prompt-modal">
      <div 
        className="crayons-modal__box" 
        role="dialog" 
        aria-labelledby="ai-modal-title"
        aria-describedby="ai-modal-desc"
      >
        <div className="crayons-modal__box__header">
          <h2 id="ai-modal-title" className="crayons-subtitle-2">Generate Cover Image with Instructions 🍌</h2>
          {!isGenerating && (
            <button 
              onClick={onClose} 
              className="crayons-btn crayons-btn--ghost crayons-btn--icon" 
              aria-label="Close"
              type="button"
            >
              <svg width="24" height="24" viewBox="0 0 24 24" class="crayons-icon" xmlns="http://www.w3.org/2000/svg">
                <path d="M12 10.586l4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636z"/>
              </svg>
            </button>
          )}
        </div>
        <div className="crayons-modal__box__body">
          <p id="ai-modal-desc" className="color-base-70 mb-4">
            Describe the image you want to generate. Be as specific as you want, or just go with vibes.
          </p>
          <form onSubmit={handleSubmit}>
            <div className="crayons-field mb-4">
              <label htmlFor="ai-prompt-input" className="crayons-field__label">
                Image Description
              </label>
              <textarea
                id="ai-prompt-input"
                data-testid="ai-prompt-input"
                className="crayons-textfield"
                rows="4"
                value={prompt}
                onInput={(e) => setPrompt(e.target.value)}
                placeholder="Example: A futuristic cityscape at sunset with flying cars and neon lights"
                disabled={isGenerating}
                required
              />
            </div>
            <div className="flex gap-2">
              <Button 
                type="submit" 
                disabled={isGenerating || !prompt.trim()}
                data-testid="generate-submit-btn"
              >
                {isGenerating ? (
                  <Fragment>
                    <Spinner /> Generating...
                  </Fragment>
                ) : (
                  'Generate Image'
                )}
              </Button>
              {!isGenerating && (
                <Button variant="secondary" onClick={onClose} type="button">
                  Cancel
                </Button>
              )}
            </div>
          </form>
        </div>
        <div className="crayons-modal__box__footer" style={{borderTop: '1px solid var(--base-20)', paddingTop: '1rem'}}>
          <p className="color-base-60 fs-s pb-4" style={{paddingLeft: '5%'}}>
            Curious how this works? The Forem codebase is{' '}
            <a 
              href="https://github.com/forem/forem/blob/main/app/services/ai/image_generator.rb" 
              target="_blank" 
              rel="noopener noreferrer"
              className="c-link"
            >
              open source 🍌
            </a>
          </p>
        </div>
      </div>
    </div>
  );
};

export const ArticleCoverImage = ({ onMainImageUrlChange, mainImage, coverImageHeight, coverImageCrop, aiAvailable, videoSourceUrl, onVideoUrlChange }) => {
  const [uploadError, setUploadError] = useState(false);
  const [uploadErrorMessage, setUploadErrorMessage] = useState(null);
  const [uploadingImage, setUploadingImage] = useState(false);
  const [showAiPrompt, setShowAiPrompt] = useState(false);
  const [generatingAiImage, setGeneratingAiImage] = useState(false);
  const [showImageOptionsModal, setShowImageOptionsModal] = useState(false);

  // Check if we're on mobile (below 768px)
  const isMobile = useMediaQuery('(max-width: 767px)');

  // Parse video URL to get embed URL and thumbnail
  const videoInfo = useMemo(() => {
    if (!videoSourceUrl) return null;
    return parseVideoUrl(videoSourceUrl);
  }, [videoSourceUrl]);

  const videoThumbnail = useMemo(() => {
    if (!videoInfo) return null;
    return getVideoThumbnail(videoInfo);
  }, [videoInfo]);

  const onImageUploadSuccess = (...args) => {
    onMainImageUrlChange(...args);
    setUploadingImage(false);
  };

  const handleMainImageUpload = (event) => {
    event.preventDefault();

    setUploadingImage(true);
    clearUploadError();

    if (validateFileInputs()) {
      const { files: image } = event.dataTransfer || event.target;
      const payload = { image };

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

  const handleGenerateClick = (e) => {
    e.preventDefault();
    setShowAiPrompt(true);
    clearUploadError();
  };

  const handleAiGenerate = (prompt) => {
    setGeneratingAiImage(true);
    clearUploadError();

    generateAiImage({
      prompt,
      successCb: (response) => {
        onMainImageUrlChange(response);
        setGeneratingAiImage(false);
        setShowAiPrompt(false);
        addSnackbarItem({
          message: 'AI image generated successfully!',
          addCloseButton: true,
        });
      },
      failureCb: (error) => {
        setGeneratingAiImage(false);
        setUploadError(true);
        setUploadErrorMessage(error.message || 'Failed to generate image. Please try again.');
      },
    });
  };

  const handleCloseAiPrompt = () => {
    if (!generatingAiImage) {
      setShowAiPrompt(false);
      clearUploadError();
    }
  };

  const useNativeUpload = () => {
    return isNativeIOS('imageUpload');
  };

  const initNativeImagePicker = (e) => {
    e.preventDefault();
    let options = { action: 'coverImageUpload' };
    if (coverImageCrop === 'crop') {
      options = { ...options, ratio: `1000.0 / ${coverImageHeight}.0`, };
    }
    window.ForemMobile?.injectNativeMessage('coverUpload', options);
  };

  const handleNativeMessage = (e) => {
    const message = JSON.parse(e.detail);
    if (message.namespace !== 'coverUpload') {
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

  const triggerMainImageRemoval = (e) => {
    e.preventDefault();
    onMainImageUrlChange({
      links: [null],
    });
  };

  const triggerVideoRemoval = (e) => {
    e.preventDefault();
    if (onVideoUrlChange) {
      onVideoUrlChange(null);
    }
  };

  const onDropImage = (event) => {
    onDragExit(event);

    if (event.dataTransfer.files.length > 1) {
      addSnackbarItem({
        message: 'Only one image can be dropped at a time.',
        addCloseButton: true,
      });
      return;
    }

    handleMainImageUpload(event);
  };

  const uploadLabel = mainImage ? 'Change' : 'Upload Cover Image';

  // When the component is rendered in an environment that supports a native
  // image picker for image upload we want to add the aria-label attr and the
  // onClick event to the UI button. This event will kick off the native UX.
  // The props are unwrapped (using spread operator) in the button below
  const extraProps = useNativeUpload()
    ? {
        onClick: initNativeImagePicker,
        'aria-label': 'Upload cover image',
      }
    : {};

  // Native Bridge messages come through ForemMobile events
  document.addEventListener('ForemMobile', handleNativeMessage);

  return (
    <Fragment>
      <DragAndDropZone
        onDragOver={onDragOver}
        onDragExit={onDragExit}
        onDrop={onDropImage}
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
          {!uploadingImage && videoInfo && !mainImage && (
            <div className="crayons-article-form__cover__video" style={{ width: '225px', height: '95px', position: 'relative', overflow: 'hidden', borderRadius: 'var(--radius)', marginRight: '10px' }}>
              {videoThumbnail ? (
                <img
                  src={videoThumbnail}
                  alt="Video thumbnail"
                  style={{ 
                    width: '100%', 
                    height: '100%', 
                    objectFit: 'cover',
                    objectPosition: 'center',
                    marginRight: '10px',
                  }}
                />
              ) : (
                <div style={{ width: '100%', height: '100%', backgroundColor: 'var(--base-20)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <span style={{ color: 'var(--base-60)' }}>▶ Video</span>
                </div>
              )}
            </div>
          )}
          <div className="flex items-center">
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
                  uploadLabel={uploadLabel}
                />
              ) : (
                <StandardImageUpload
                  isUploadingImage={uploadingImage}
                  uploadLabel={uploadLabel}
                  coverImageHeight={coverImageHeight}
                  coverImageCrop={coverImageCrop}
                  handleImageUpload={handleMainImageUpload}
                  onGenerateClick={handleGenerateClick}
                  aiAvailable={aiAvailable}
                  videoSourceUrl={videoSourceUrl}
                  onVideoUrlChange={onVideoUrlChange}
                  isMobile={isMobile}
                  onImageButtonClick={(e) => {
                    e.preventDefault();
                    setShowImageOptionsModal(true);
                  }}
                  showImageOptionsModal={showImageOptionsModal}
                  onCloseImageOptionsModal={() => setShowImageOptionsModal(false)}
                />
              )}

              {mainImage && !uploadingImage && (
                <Button 
                  variant="ghost-danger" 
                  onClick={triggerMainImageRemoval}
                  className="whitespace-nowrap"
                  style={{minHeight: '2.5rem', display: 'inline-flex', alignItems: 'center'}}
                >
                  Remove
                </Button>
              )}
              {videoSourceUrl && !uploadingImage && !mainImage && (
                <Button 
                  variant="ghost-danger" 
                  onClick={triggerVideoRemoval}
                  className="whitespace-nowrap"
                  style={{minHeight: '2.5rem', display: 'inline-flex', alignItems: 'center'}}
                  data-testid="remove-video-cover-btn"
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
      
      {showAiPrompt && (
        <AiImagePromptModal 
          onClose={handleCloseAiPrompt}
          onGenerate={handleAiGenerate}
          isGenerating={generatingAiImage}
        />
      )}
    </Fragment>
  );
};

ArticleCoverImage.propTypes = {
  mainImage: PropTypes.string,
  onMainImageUrlChange: PropTypes.func.isRequired,
  coverImageHeight: PropTypes.string.isRequired,
  coverImageCrop: PropTypes.string.isRequired,
  aiAvailable: PropTypes.bool.isRequired,
  videoSourceUrl: PropTypes.string,
  onVideoUrlChange: PropTypes.func,
};

ArticleCoverImage.displayName = 'ArticleCoverImage';
