import PropTypes from 'prop-types';
import { tagPropTypes } from './tag-prop-types';

export const selectedTagsPropTypes = PropTypes.shape({
  tags: PropTypes.arrayOf(tagPropTypes).isRequired,
  onClick: PropTypes.func.isRequired,
  onKeyPress: PropTypes.func.isRequired,
});
