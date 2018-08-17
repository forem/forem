import { h } from 'preact';
import PropTypes from 'prop-types';

const Notice = ({ published }) => (
  <div className={'articleform__notice articleform__notice--'+(published ? "publishing" : "draft")}>{published ? "Publishing..." : "Saving Draft..."}</div>
);

Notice.propTypes = {
  published: PropTypes.bool.isRequired,
};

export default Notice;
