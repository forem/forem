import { h } from 'preact';
import PropTypes from 'prop-types';

/* global timeAgo */

export const PublishDate = ({
  readablePublishDate,
  publishedTimestamp,
  publishedAtInt,
}) => {
  const timeAgoIndicator = timeAgo({
    oldTimeInSeconds: publishedAtInt,
    formatter: (x) => x,
  });

  return (
    <time dateTime={publishedTimestamp}>
      {timeAgoIndicator.length > 0 ? timeAgoIndicator : readablePublishDate}
    </time>
  );
};

PublishDate.defaultProps = {
  publishedTimestamp: null,
  publishedAtInt: null,
};

PublishDate.propTypes = {
  readablePublishDate: PropTypes.string.isRequired,
  publishedTimestamp: PropTypes.string,
  publishedAtInt: PropTypes.string,
};

PublishDate.displayName = 'PublishDate';
