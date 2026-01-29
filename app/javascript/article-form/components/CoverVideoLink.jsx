import { h, Fragment } from 'preact';
import { useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { useMediaQuery, BREAKPOINTS } from '@components/useMediaQuery';
import { Button } from '@crayons';

const VideoLinkModal = ({ onClose, onSave, currentUrl, isOpen }) => {
  const [url, setUrl] = useState(currentUrl || '');
  const [error, setError] = useState(null);
  const isWideScreen = useMediaQuery(`(min-width: ${BREAKPOINTS.Medium}px)`);

  if (!isOpen) return null;

  const validateUrl = (videoUrl) => {
    if (!videoUrl || !videoUrl.trim()) {
      return false;
    }

    const trimmedUrl = videoUrl.trim();
    // Check for YouTube URLs
    const youtubePattern = /^https?:\/\/(www\.)?(youtube\.com\/watch\?v=|youtu\.be\/)/;
    // Check for Mux URLs
    const muxPattern = /^https?:\/\/player\.mux\.com\//;
    // Check for Twitch video URLs
    const twitchPattern = /^https?:\/\/(www\.)?twitch\.tv\/videos\//;

    return youtubePattern.test(trimmedUrl) || muxPattern.test(trimmedUrl) || twitchPattern.test(trimmedUrl);
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    setError(null);

    const trimmedUrl = url.trim();
    
    if (!trimmedUrl) {
      onSave('');
      onClose();
      return;
    }

    if (!validateUrl(trimmedUrl)) {
      setError('Please enter a valid YouTube, Mux, or Twitch video URL.');
      return;
    }

    onSave(trimmedUrl);
    onClose();
  };

  const handleCancel = () => {
    setUrl(currentUrl || '');
    setError(null);
    onClose();
  };

  return (
    <div className="crayons-modal crayons-modal--m" data-testid="video-link-modal">
      <div 
        className="crayons-modal__box" 
        role="dialog" 
        aria-labelledby="video-modal-title"
        aria-describedby="video-modal-desc"
      >
        <div className="crayons-modal__box__header">
          <h2 id="video-modal-title" className="crayons-subtitle-2">Add Cover Video Link</h2>
          <button 
            onClick={handleCancel} 
            className="crayons-btn crayons-btn--ghost crayons-btn--icon"
            style={{maxWidth: '60px'}}
            aria-label="Close"
            type="button"
          >
            <svg width="24" height="24" viewBox="0 0 24 24" class="crayons-icon" xmlns="http://www.w3.org/2000/svg">
              <path d="M12 10.586l4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636z"/>
            </svg>
          </button>
        </div>
        <div className="crayons-modal__box__body">
          <p id="video-modal-desc" className="color-base-70 mb-4">
            Enter a YouTube, Mux, or Twitch video URL to use as the cover video for your article.
          </p>
          <form onSubmit={handleSubmit}>
            <div className="crayons-field mb-4">
              <label htmlFor="video-url-input" className="crayons-field__label">
                Video URL
              </label>
              <input
                id="video-url-input"
                data-testid="video-url-input"
                className="crayons-textfield"
                type="url"
                value={url}
                onInput={(e) => {
                  setUrl(e.target.value);
                  setError(null);
                }}
                placeholder="https://www.youtube-or-mux-or-twitch.com/watch?v=..."
                required={false}
              />
              {error && (
                <p className="crayons-field__description color-accent-danger mt-2">
                  {error}
                </p>
              )}
              <div className="mt-3 pt-2" style={{ borderTop: '1px solid var(--base-20)' }}>
                <p className="fs-s fw-medium mb-3 color-base-90">Supported formats:</p>
                <div className={`flex gap-3 ${isWideScreen ? 'flex-row' : 'flex-col'}`}>
                  <div style={{ border: '1px solid var(--base-20)', borderRadius: 'var(--radius)', padding: '12px', flex: '1' }}>
                    <p className="fs-s fw-medium mb-2 color-base-90">YouTube</p>
                    <div className="flex flex-col gap-1">
                      <code className="fs-xs color-base-70" style={{ backgroundColor: 'var(--base-10)', padding: '2px 6px', borderRadius: 'var(--radius)', display: 'inline-block', width: 'fit-content' }}>
                        youtube.com/watch?v=...
                      </code>
                      <code className="fs-xs color-base-70" style={{ backgroundColor: 'var(--base-10)', padding: '2px 6px', borderRadius: 'var(--radius)', display: 'inline-block', width: 'fit-content' }}>
                        youtu.be/...
                      </code>
                    </div>
                  </div>
                  <div style={{ border: '1px solid var(--base-20)', borderRadius: 'var(--radius)', padding: '12px', flex: '1' }}>
                    <p className="fs-s fw-medium mb-2 color-base-90">Mux</p>
                    <div>
                      <code className="fs-xs color-base-70" style={{ backgroundColor: 'var(--base-10)', padding: '2px 6px', borderRadius: 'var(--radius)', display: 'inline-block', width: 'fit-content' }}>
                        player.mux.com/...
                      </code>
                    </div>
                  </div>
                  <div style={{ border: '1px solid var(--base-20)', borderRadius: 'var(--radius)', padding: '12px', flex: '1' }}>
                    <p className="fs-s fw-medium mb-2 color-base-90">Twitch</p>
                    <div>
                      <code className="fs-xs color-base-70" style={{ backgroundColor: 'var(--base-10)', padding: '2px 6px', borderRadius: 'var(--radius)', display: 'inline-block', width: 'fit-content' }}>
                        twitch.tv/videos/...
                      </code>
                    </div>
                    <p className="fs-xs color-base-60 mt-2 mb-0">*only direct video links, not channel stream</p>
                  </div>
                </div>
              </div>
            </div>
            <div className="flex gap-2">
              <Button 
                type="submit"
                data-testid="save-video-btn"
              >
                {currentUrl ? 'Update Link' : 'Add Link'}
              </Button>
              <Button variant="secondary" onClick={handleCancel} type="button">
                Cancel
              </Button>
              {currentUrl && (
                <Button 
                  variant="ghost-danger" 
                  onClick={() => {
                    onSave('');
                    onClose();
                  }}
                  type="button"
                  data-testid="remove-video-btn"
                >
                  Remove
                </Button>
              )}
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

VideoLinkModal.propTypes = {
  onClose: PropTypes.func.isRequired,
  onSave: PropTypes.func.isRequired,
  currentUrl: PropTypes.string,
  isOpen: PropTypes.bool.isRequired,
};

export const CoverVideoLink = ({ videoSourceUrl, onVideoUrlChange }) => {
  const [showModal, setShowModal] = useState(false);

  const handleSave = (url) => {
    onVideoUrlChange(url || null);
  };

  return (
    <Fragment>
      <Button
        variant="outlined"
        onClick={(e) => {
          e.preventDefault();
          setShowModal(true);
        }}
        className="mr-2 whitespace-nowrap"
        data-testid="add-cover-video-btn"
        style={{minHeight: '2.5rem', display: 'inline-flex', alignItems: 'center'}}
      >
        {videoSourceUrl ? 'Change Video Link' : 'Cover Video Link'}
      </Button>
      <VideoLinkModal
        isOpen={showModal}
        onClose={() => setShowModal(false)}
        onSave={handleSave}
        currentUrl={videoSourceUrl}
      />
    </Fragment>
  );
};

CoverVideoLink.propTypes = {
  videoSourceUrl: PropTypes.string,
  onVideoUrlChange: PropTypes.func.isRequired,
};

CoverVideoLink.displayName = 'CoverVideoLink';

