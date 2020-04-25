import { h } from 'preact';
import PropTypes from 'prop-types';
import { Cover } from './Cover';
import { TagsField } from './TagsField';
import { Title } from './Title';

export const Meta = ({
  titleDefaultValue,
  titleOnKeyDown,
  titleOnChange,
  tagsDefaultValue,
  tagsOnInput,
}) => {
  return (
    <div>
      <Cover />
      <Title
        defaultValue={titleDefaultValue}
        onKeyDown={titleOnKeyDown}
        onChange={titleOnChange}
      />

      <TagsField defaultValue={tagsDefaultValue} onInput={tagsOnInput} />
    </div>
  );
};



Meta.propTypes = {
  titleDefaultValue: PropTypes.string.isRequired,
  titleOnKeyDown: PropTypes.func.isRequired,
  titleOnChange: PropTypes.func.isRequired,
  tagsDefaultValue: PropTypes.string.isRequired,
  tagsOnInput: PropTypes.func.isRequired,
}

Meta.displayName = 'Meta';
