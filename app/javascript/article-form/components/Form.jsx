import { h } from 'preact';
import PropTypes from 'prop-types';
import { Body } from './Body';
import { Meta } from './Meta';

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
  onMainImageUrlChange
}) => {
  return (
    <div className="crayons-card crayons-layout__content crayons-article-form__fields">
      {version === 'v2' && (
        <Meta
          titleDefaultValue={titleDefaultValue}
          titleOnChange={titleOnChange}
          tagsDefaultValue={tagsDefaultValue}
          tagsOnInput={tagsOnInput}
          mainImage={mainImage}
          onMainImageUrlChange={onMainImageUrlChange}
        />
      )}

      <Body
        defaultValue={bodyDefaultValue}
        onChange={bodyOnChange}
        hasFocus={bodyHasFocus}
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
  mainImage: PropTypes.string.isRequired,
  onMainImageUrlChange: PropTypes.func.isRequired,
}

Form.displayName = 'Form';
