/* global timestampToLocalDateTimeLong timestampToLocalDateTimeShort */

import PropTypes from 'prop-types';
import { h } from 'preact';

const DateTime = ({ dateTime, className }) => (
  <time
    dateTime={dateTime}
    title={timestampToLocalDateTimeLong(dateTime)}
    className={className}
    data-testid="date-time-formatting"
  >
    {timestampToLocalDateTimeShort(dateTime)}
  </time>
);

DateTime.defaultProps = {
  className: '',
};

DateTime.propTypes = {
  datetime: PropTypes.instanceOf(Date),
  className: PropTypes.string,
};

export default DateTime;
