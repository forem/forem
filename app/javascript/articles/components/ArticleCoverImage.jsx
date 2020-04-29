import { h } from 'preact';
import { articlePropTypes } from '../../src/components/common-prop-types';

export const ArticleCoverImage = ({ article }) => {
  return (
    <a href={article.path} className="crayons-story__cover">
      <img
        src={article.main_image}
        className="crayons-story__cover__image"
        alt={article.title}
        loading="lazy"
      />
    </a>
  );
};

ArticleCoverImage.propTypes = {
  article: articlePropTypes.isRequired,
};

ArticleCoverImage.displayName = 'ArticleCoverImage';
