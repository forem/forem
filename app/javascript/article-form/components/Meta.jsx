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
  coverImageCrop,
  coverImageHeight,
  aiAvailable,
  videoSourceUrl,
  onVideoUrlChange,
  coAuthorsData,
}) => {
  return (
    <div className="crayons-article-form__top text-padding drop-area">
      <ArticleCoverImage
        mainImage={mainImage}
        onMainImageUrlChange={onMainImageUrlChange}
        coverImageCrop={coverImageCrop}
        coverImageHeight={coverImageHeight}
        aiAvailable={aiAvailable}
        videoSourceUrl={videoSourceUrl}
        onVideoUrlChange={onVideoUrlChange}
      />
      <Title
        defaultValue={titleDefaultValue}
        onChange={titleOnChange}
        switchHelpContext={switchHelpContext}
      />
      <TagsField
        defaultValue={tagsDefaultValue}
        onInput={tagsOnInput}
        switchHelpContext={switchHelpContext}
      />
      {coAuthorsData?.length > 0 && (
        <div className="spec-article__co_authors color-base-60 mt-2 text-sm">
          Co-authored by: {coAuthorsData.map(u => (
            <span key={u.id} className="fw-bold mr-1">
              {u.name} (@{u.username})
            </span>
          ))}
        </div>
      )}
    </div>
  );
};

Meta.propTypes = {
  titleDefaultValue: PropTypes.string.isRequired,
  titleOnChange: PropTypes.func.isRequired,
  tagsDefaultValue: PropTypes.string.isRequired,
  tagsOnInput: PropTypes.func.isRequired,
  mainImage: PropTypes.string,
  onMainImageUrlChange: PropTypes.func.isRequired,
  switchHelpContext: PropTypes.func.isRequired,
  coverImageHeight: PropTypes.string.isRequired,
  coverImageCrop: PropTypes.string.isRequired,
  aiAvailable: PropTypes.bool.isRequired,
  videoSourceUrl: PropTypes.string,
  onVideoUrlChange: PropTypes.func,
  coAuthorsData: PropTypes.array,
};

Meta.displayName = 'Meta';
