import { h } from 'preact';
import PropTypes from 'prop-types';
import Tags from '../../shared/components/tags';

export const TagsField = ({ defaultValue, onInput, switchHelpContext }) => {
  return (
    <div data-testid="article-form__tagsfield" className="crayons-article-form__tagsfield">
      <Tags
        defaultValue={defaultValue}
        maxTags="4"
        onInput={onInput}
        onFocus={switchHelpContext}
        classPrefix="crayons-article-form"
        fieldClassName="crayons-textfield crayons-textfield--ghost ff-accent"
      />
    </div>
  );
};

TagsField.propTypes = {
  onInput: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
  switchHelpContext: PropTypes.func.isRequired,
};

TagsField.displayName = 'TagsField';
