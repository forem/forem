import { h } from 'preact';
import { useEffect } from 'preact/hooks';
import PropTypes from 'prop-types';
import { EditorBody } from './EditorBody';
import { Meta } from './Meta';
import { ErrorList } from './ErrorList';

function scrollToTop() {
  window.scrollTo({ top: 0, behavior: "smooth" });

  const el = document.getElementById("CreatePost_Content");
  if (!el) return;

  if (el.scrollHeight > el.clientHeight) {
    el.scrollTop = 0;
  }
}

export const Form = ({
  titleDefaultValue,
  titleOnChange,
  tagsDefaultValue,
  tagsOnInput,
  bodyDefaultValue,
  bodyOnChange,
  bodyHasFocus,
  version,
  mainImage,
  onMainImageUrlChange,
  switchHelpContext,
  errors,
  coverImageCrop,
  coverImageHeight,
  aiAvailable,
  videoSourceUrl,
  onVideoUrlChange,
}) => {

  useEffect(() => {
    if (errors) {
      scrollToTop();
    }
  }, [errors]);

  return (
    <div className="crayons-article-form__content crayons-card" id="CreatePost_Content">
      {errors && <ErrorList errors={errors} />}

      {version === 'v2' && (
        <Meta
          titleDefaultValue={titleDefaultValue}
          titleOnChange={titleOnChange}
          tagsDefaultValue={tagsDefaultValue}
          tagsOnInput={tagsOnInput}
          mainImage={mainImage}
          onMainImageUrlChange={onMainImageUrlChange}
          switchHelpContext={switchHelpContext}
          coverImageCrop={coverImageCrop}
          coverImageHeight={coverImageHeight}
          aiAvailable={aiAvailable}
          videoSourceUrl={videoSourceUrl}
          onVideoUrlChange={onVideoUrlChange}
        />
      )}

      <EditorBody
        defaultValue={bodyDefaultValue}
        onChange={bodyOnChange}
        hasFocus={bodyHasFocus}
        switchHelpContext={switchHelpContext}
        version={version}
      />
    </div>
  );
};

Form.propTypes = {
  titleDefaultValue: PropTypes.string.isRequired,
  titleOnChange: PropTypes.func.isRequired,
  tagsDefaultValue: PropTypes.string.isRequired,
  tagsOnInput: PropTypes.func.isRequired,
  bodyDefaultValue: PropTypes.string.isRequired,
  bodyOnChange: PropTypes.func.isRequired,
  bodyHasFocus: PropTypes.bool.isRequired,
  version: PropTypes.string.isRequired,
  mainImage: PropTypes.string,
  onMainImageUrlChange: PropTypes.func.isRequired,
  switchHelpContext: PropTypes.func.isRequired,
  errors: PropTypes.object,
  coverImageHeight: PropTypes.string.isRequired,
  coverImageCrop: PropTypes.string.isRequired,
  aiAvailable: PropTypes.bool.isRequired,
  videoSourceUrl: PropTypes.string,
  onVideoUrlChange: PropTypes.func,
};

Form.displayName = 'Form';
