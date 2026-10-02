import { h } from 'preact';
import { articlePropTypes } from '../../common-prop-types';

export const ArticleCoverImage = ({ article }) => {
  const handleImageError = (event) => {
    event.currentTarget.closest('.crayons-article__cover')?.remove();
  };

  return (
    <div
      className="crayons-article__cover crayons-article__cover__image__feed"
      style={{
        aspectRatio: `auto 1000 / ${article.main_image_height}`,
      }}
    >
      <a
        href={article.url}
        className="crayons-article__cover__image__feed crayons-story__cover__image"
        title={article.title}
      >
        <img
          className="crayons-article__cover__image__feed"
          src={article.main_image}
          width="1000"
          height={article.main_image_height}
          alt={article.title}
          onError={handleImageError}
        />
      </a>
    </div>
  );
};

ArticleCoverImage.propTypes = {
  article: articlePropTypes.isRequired,
};

ArticleCoverImage.displayName = 'ArticleCoverImage';
