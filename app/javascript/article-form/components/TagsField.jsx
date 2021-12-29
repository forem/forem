import { h } from 'preact';
import PropTypes from 'prop-types';
import { Tags } from '../../shared/components/tags';

export const DEFAULT_TAG_FORMAT = '[0-9A-Za-z, ]+';

export const TagsField = ({
  defaultValue,
  onInput,
  switchHelpContext,
  tagFormat = DEFAULT_TAG_FORMAT,
}) => {
  return (
    <div className="crayons-article-form__tagsfield">
      <Tags
        defaultValue={defaultValue}
        maxTags={4}
        onInput={onInput}
        onFocus={switchHelpContext}
        classPrefix="crayons-article-form"
        fieldClassName="crayons-textfield crayons-textfield--ghost ff-monospace"
        pattern={tagFormat}
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
