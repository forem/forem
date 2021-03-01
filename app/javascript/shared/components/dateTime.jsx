/* global timestampToLocalDateTimeLong timestampToLocalDateTimeShort */

import PropTypes from 'prop-types';
import { h } from 'preact';

export const DateTime = ({ dateTime, className }) => (
  <time
    dateTime={dateTime}
    title={timestampToLocalDateTimeLong(dateTime)}
    className={className}
  >
    {timestampToLocalDateTimeShort(dateTime)}
  </time>
);

DateTime.defaultProps = {
  className: '',
};

DateTime.propTypes = {
  dateTime: PropTypes.instanceOf(Date).isRequired,
  className: PropTypes.string,
};
