import PropTypes from 'prop-types';
import { h } from 'preact';

const SingleArticle = ({
  id,
  title,
  path,
  cachedTagList,
  publishedAt,
  user,
  toggleArticle,
}) => {
  const tags = cachedTagList.split(', ').map((tag) => {
    return (
      <span className="mod-article-tag">
        <span className="article-hash-tag">#</span>
        {tag}
      </span>
    );
  });

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  const get12HourTime = (date) => {
    const minutes = date.getMinutes();
    let hours = date.getHours();
    const AmOrPm = hours >= 12 ? 'PM' : 'AM';
    hours = hours % 12 || 12;

    return `${hours}:${minutes} ${AmOrPm}`;
  };

  const formatDate = (timestamp) => {
    const dateToday = new Date();
    const origDatePublished = new Date(timestamp);

    if (dateToday.toDateString() === origDatePublished.toDateString()) {
      return get12HourTime(origDatePublished);
    }
    return `${
      months[origDatePublished.getMonth()]
    } ${origDatePublished.getDate()}`;
  };

  const newAuthorNotification = () => {
    if (user.articles_count <= 3) {
      return '👋 ';
    }
    return '';
  };

  return (
    <button
      type="button"
      className="moderation-single-article"
      onClick={(e) => toggleArticle(e, id, path)}
    >
      <span className="article-title">
        <header>
          <h3>{title}</h3>
        </header>
        {tags}
      </span>
      <span className="article-author">
        {newAuthorNotification()}
        {user.name}
      </span>
      <span className="article-published-at">{formatDate(publishedAt)}</span>
      <div className="article-iframes-container" id={`article-iframe-${id}`} />
    </button>
  );
};

SingleArticle.propTypes = {
  id: PropTypes.number.isRequired,
  title: PropTypes.string.isRequired,
  path: PropTypes.string.isRequired,
  publishedAt: PropTypes.string.isRequired,
  cachedTagList: PropTypes.isRequired,
  user: PropTypes.isRequired,
  toggleArticle: PropTypes.func.isRequired,
};

export default SingleArticle;
