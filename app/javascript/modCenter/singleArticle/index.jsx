import PropTypes from 'prop-types';
import { h, Fragment } from 'preact';
import { formatDate } from './util';

export const SingleArticle = ({
  id,
  title,
  publishedAt,
  cachedTagList,
  user,
  key,
  articleOpened,
  path,
  toggleArticle,
}) => {
  const activateToggle = () => toggleArticle(id, title, path);

  const tagsFormat = (tag, key) => {
    if (tag) {
      return (
        <span className="crayons-tag" key={key}>
          <span className="crayons-tag__prefix">#</span>
          {tag}
        </span>
      );
    }
  };

  const tags = cachedTagList.split(', ').map((tag) => tagsFormat(tag, key));

  const newAuthorNotification = user.articles_count <= 3 ? '👋 ' : '';

  return (
    <Fragment>
      <details
        id={`mod-article-${id}`}
        data-testid={`mod-article-${id}`}
        className="moderation-single-article"
        onToggle={activateToggle}
      >
        <summary>
          <div className="article-details-container">
            <span className="article-title">
              <header>
                <h3 className="fs-base fw-bold lh-tight article-title-heading">
                  {title}
                </h3>
              </header>
              {tags}
            </span>
            <span className="article-author">
              {newAuthorNotification}
              {user.name}
            </span>
            <span className="article-published-at">
              <time dateTime={publishedAt}>{formatDate(publishedAt)}</time>
            </span>
          </div>
        </summary>
        <div
          className={`article-iframes-container${
            articleOpened ? ' opened' : ''
          }`}
          id={`article-iframe-${id}`}
        />
      </details>
    </Fragment>
  );
};

SingleArticle.propTypes = {
  id: PropTypes.number.isRequired,
  title: PropTypes.string.isRequired,
  path: PropTypes.string.isRequired,
  publishedAt: PropTypes.string.isRequired,
  cachedTagList: PropTypes.isRequired,
  user: PropTypes.isRequired,
  key: PropTypes.number.isRequired,
};
