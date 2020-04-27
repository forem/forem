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
  mainImage,
  onMainImageUrlChange,
}) => {
  return (
    <div>
      <Cover
        mainImage={mainImage}
        onMainImageUrlChange={onMainImageUrlChange}
      />
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
  mainImage: PropTypes.string.isRequired,
  onMainImageUrlChange: PropTypes.func.isRequired
};

Meta.displayName = 'Meta';
