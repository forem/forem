import { h } from 'preact';
import PropTypes from 'prop-types';
import { Body } from './Body';
import { Meta } from './Meta';

export const Form = ({
  titleDefaultValue,
  titleOnKeyDown,
  titleOnChange,
  tagsDefaultValue,
  tagsOnInput,
  bodyDefaultValue,
  bodyOnKeyDown,
  bodyOnChange,
  bodyHasFocus,
  version
}) => {
  return (
    <div className="crayons-card crayons-layout__content crayons-article-form__fields">
      {version === 'v2' && (
        <Meta
          titleDefaultValue={titleDefaultValue}
          titleOnKeyDown={titleOnKeyDown}
          titleOnChange={titleOnChange}
          tagsDefaultValue={tagsDefaultValue}
          tagsOnInput={tagsOnInput}
        />
      )}

      <Body
        defaultValue={bodyDefaultValue}
        onKeyDown={bodyOnKeyDown}
        onChange={bodyOnChange}
        hasFocus={bodyHasFocus}
      />
    </div>
  );
};



Form.propTypes = {
  titleDefaultValue: PropTypes.string.isRequired,
  titleOnKeyDown: PropTypes.func.isRequired,
  titleOnChange: PropTypes.func.isRequired,
  tagsDefaultValue: PropTypes.string.isRequired,
  tagsOnInput: PropTypes.func.isRequired,
  bodyDefaultValue: PropTypes.string.isRequired,
  bodyOnKeyDown: PropTypes.func.isRequired,
  bodyOnChange: PropTypes.func.isRequired,
  bodyHasFocus: PropTypes.bool.isRequired,
  version: PropTypes.string.isRequired
}

Form.displayName = 'Form';
