import { h } from 'preact';
import PropTypes from 'prop-types';

export const ReadingTime = ({ readingTime }) => {
  // we have ` ... || null` for the case article.reading_time is undefined
  return (
    <small className="crayons-story__tertiary mr-2 fs-xs">
      {`${readingTime < 1 ? 1 : readingTime} min read`}
    </small>
  );
};

ReadingTime.defaultProps = {
  readingTime: null,
};

ReadingTime.propTypes = {
  readingTime: PropTypes.number,
};

ReadingTime.displayName = 'ReadingTime';
