import { h } from 'preact';
import PropTypes from 'prop-types';
import { timestampToLocalDateTimeShort } from '../../utilities/localDateTime';

/* global timeAgo */

export const PublishDate = ({
  readablePublishDate,
  publishedTimestamp,
  publishedAtInt,
}) => {
  const timeAgoIndicator = timeAgo({
    oldTimeInSeconds: publishedAtInt,
    formatter: (x) => x,
    maxDisplayedAge: 60 * 60 * 24 * 7,
  });

  const timeAgoText = () => {
    if (timeAgoIndicator) {
      return ` (${timeAgoIndicator})`;
    }
    return '';
  };

  // Format date using user's local timezone instead of server timezone
  const formattedDate = publishedTimestamp
    ? timestampToLocalDateTimeShort(publishedTimestamp)
    : readablePublishDate; // Fallback to server-formatted date if timestamp is missing

  return (
    <time dateTime={publishedTimestamp}>
      {formattedDate}
      {timeAgoText()}
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
  publishedAtInt: PropTypes.number,
};

PublishDate.displayName = 'PublishDate';
