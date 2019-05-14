import { h } from 'preact';
import PropTypes from 'prop-types';

const Notice = ({ published, version }) => (
  <div
    className={`articleform__notice articleform__notice--${
      published ? 'publishing' : 'draft'
    }`}
  >
    {(published && version === 'v2') ? 'Publishing...' : `Saving ${ version === 'v2' ? 'Draft' : ''}...`}
  </div>
);

Notice.propTypes = {
  published: PropTypes.bool.isRequired,
  version: PropTypes.string.isRequired,
};

export default Notice;
