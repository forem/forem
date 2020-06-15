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
    <div className="moderation-single-article">
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
