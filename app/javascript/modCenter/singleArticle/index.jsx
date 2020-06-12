import PropTypes from 'prop-types';
import { h } from 'preact';

const SingleArticle = ({
  title,
  // path,
  cachedTagList,
  publishedAt,
  user,
}) => {
  const tags = cachedTagList.split(', ').map((tag) => {
    return (
      <span className="mod-article-tag">
        <span className="article-hash-tag">#</span>
        {tag}
      </span>
    );
  });

  return (
    <div className="moderation-single-article">
      <span className="article-title">
        <header>
          <h3>{title}</h3>
        </header>
        {tags}
      </span>
      <span className="article-author">{user.name}</span>
      <span className="article-published-at">{publishedAt}</span>
    </div>
  );
};

SingleArticle.propTypes = {
  title: PropTypes.string.isRequired,
  // path: PropTypes.string.isRequired,
  publishedAt: PropTypes.string.isRequired,
  cachedTagList: PropTypes.isRequired,
  user: PropTypes.isRequired,
};

export default SingleArticle;
