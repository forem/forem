import { h } from 'preact';
import PropTypes from 'prop-types';
import Tags from '../../shared/components/tags';

export const TagsField = ({defaultValue, onInput}) => {
  return (
    <div className="crayons-article-form__tagsfield">
      <Tags
        defaultValue={defaultValue}
        maxTags="4"
        onInput={onInput}
        classPrefix="crayons-article-form"
        fieldClassName="crayons-textfield crayons-textfield--ghost ff-accent"
      />
    </div>
  );
};

TagsField.propTypes = {
  onInput: PropTypes.func.isRequired,
  defaultValue: PropTypes.string.isRequired,
};

TagsField.displayName = 'TagsField';
