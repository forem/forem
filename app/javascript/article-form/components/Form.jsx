import { h } from 'preact';
import PropTypes from 'prop-types';
import { EditorBody } from './EditorBody';
import { Meta } from './Meta';
import { ErrorList } from './ErrorList';
// import { TagsField } from './TagsField';

export const Form = ({
  titleDefaultValue,
  titleOnChange,
  tagsDefaultValue,
  tagsOnInput,
  imagesDefaultValue,
  imagesOnInput,
  bodyDefaultValue,
  bodyOnChange,
  bodyHasFocus,
  version,
  mainImage,
  onMainImageUrlChange,
  switchHelpContext,
  errors,
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
        />
      )}

      {/* {version === 'v0' && (
        <div className="crayons-article-form__top text-padding drop-area" style="padding-bottom: 0">
          <TagsField
            defaultValue={tagsDefaultValue}
            onInput={tagsOnInput}
            switchHelpContext={switchHelpContext}
          />
        </div>
      )} */}

      <EditorBody
        defaultValue={bodyDefaultValue}
        onChange={bodyOnChange}
        hasFocus={bodyHasFocus}
        switchHelpContext={switchHelpContext}
        tagsDefaultValue={tagsDefaultValue}
        tagsOnInput={tagsOnInput}
        imagesDefaultValue={imagesDefaultValue}
        imagesOnInput={imagesOnInput}
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
  imagesDefaultValue: PropTypes.string.isRequired,
  imagesOnInput: PropTypes.func.isRequired,
  bodyDefaultValue: PropTypes.string.isRequired,
  bodyOnChange: PropTypes.func.isRequired,
  bodyHasFocus: PropTypes.bool.isRequired,
  version: PropTypes.string.isRequired,
  mainImage: PropTypes.string,
  onMainImageUrlChange: PropTypes.func.isRequired,
  switchHelpContext: PropTypes.func.isRequired,
  errors: PropTypes.object,
};

Form.displayName = 'Form';
