import { h } from 'preact';
import PropTypes from 'prop-types';
import { ArticleCoverImage } from './ArticleCoverImage';
import { TagsField } from './TagsField';
import { Title } from './Title';

export const Meta = ({
  titleDefaultValue,
  titleOnChange,
  tagsDefaultValue,
  tagsOnInput,
  mainImage,
  onMainImageUrlChange,
  switchHelpContext,
  disableGrammarly,
}) => {
  return (
    <div className="crayons-article-form__top text-padding drop-area">
      <ArticleCoverImage
        mainImage={mainImage}
        onMainImageUrlChange={onMainImageUrlChange}
      />
      <Title
        defaultValue={titleDefaultValue}
        disableGrammarly={disableGrammarly}
        onChange={titleOnChange}
        switchHelpContext={switchHelpContext}
      />
      <TagsField
        defaultValue={tagsDefaultValue}
        onInput={tagsOnInput}
        switchHelpContext={switchHelpContext}
      />
    </div>
  );
};

Meta.propTypes = {
  disableGrammarly: PropTypes.bool.isRequired,
  titleDefaultValue: PropTypes.string.isRequired,
  titleOnChange: PropTypes.func.isRequired,
  tagsDefaultValue: PropTypes.string.isRequired,
  tagsOnInput: PropTypes.func.isRequired,
  mainImage: PropTypes.string.isRequired,
  onMainImageUrlChange: PropTypes.func.isRequired,
  switchHelpContext: PropTypes.func.isRequired,
};

Meta.displayName = 'Meta';
