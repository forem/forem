import { h } from 'preact';
import PropTypes from 'prop-types';

export const PublishDate = ({ readablePublishDate, publishedTimestamp }) => {
  if (publishedTimestamp) {
    return <time dateTime={publishedTimestamp}>{readablePublishDate}</time>;
  }

  return <time>{readablePublishDate}</time>;
};

PublishDate.defaultProps = {
  publishedTimestamp: null,
};

PublishDate.propTypes = {
  readablePublishDate: PropTypes.string.isRequired,
  publishedTimestamp: PropTypes.string,
};

PublishDate.displayName = 'PublishDate';
