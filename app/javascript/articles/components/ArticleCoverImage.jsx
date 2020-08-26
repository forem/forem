import { h } from 'preact';
import { articlePropTypes } from '../../common-prop-types';

export const ArticleCoverImage = ({ article }) => {
  return (
    <a
      href={article.path}
      className="crayons-story__cover"
      title={article.title}
      style={{ backgroundImage: `url(${article.main_image})` }}
    >
      <span class="hidden">{article.title}</span>
    </a>
  );
};

ArticleCoverImage.propTypes = {
  article: articlePropTypes.isRequired,
};

ArticleCoverImage.displayName = 'ArticleCoverImage';
