import { h } from 'preact';
import { articlePropTypes } from '../../common-prop-types';

export const ArticleCoverImage = ({ article }) => {
  return (
    <a
      href={article.path}
      className="crayons-story__cover"
      title={article.title}
    >
      <div
        style={{ backgroundImage: `url(${article.main_image})` }}
        className="crayons-story__cover__image"
      />
    </a>
  );
};

ArticleCoverImage.propTypes = {
  article: articlePropTypes.isRequired,
};

ArticleCoverImage.displayName = 'ArticleCoverImage';
