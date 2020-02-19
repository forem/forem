import { h } from 'preact';
import PropTypes from 'prop-types';

export const CommentsCount = ({ count, articlePath, icon }) => {
  if (count > 0) {
    return (
      <div className="article-engagement-count comments-count">
        <a href={`${articlePath}#comments`}>
          <img src={icon} alt="chat" loading="lazy" />
          <span className="engagement-count-number">{count}</span>
        </a>
      </div>
    );
  }

  return null;
};

CommentsCount.defaultProps = {
  count: 0,
};

CommentsCount.propTypes = {
  count: PropTypes.number,
  articlePath: PropTypes.string.isRequired,
  icon: PropTypes.string.isRequired,
};

CommentsCount.displayName = 'CommentsCount';
