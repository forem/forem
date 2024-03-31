import { h } from 'preact';
import PropTypes from 'prop-types';
import { EditorBody } from './EditorBody';
import { Meta } from './Meta';
import { ErrorList } from './ErrorList';

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
}) => {
  return (
    <div className="crayons-article-form__content crayons-card">
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
};

Form.displayName = 'Form';
