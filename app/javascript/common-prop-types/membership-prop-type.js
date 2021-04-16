import PropTypes from 'prop-types';

export const defaultMembershipPropType = PropTypes.shape({
  name: PropTypes.string.isRequired,
  membership_id: PropTypes.number.isRequired,
  user_id: PropTypes.number.isRequired,
  role: PropTypes.string.isRequired,
  image: PropTypes.string.isRequired,
  username: PropTypes.string.isRequired,
  status: PropTypes.string.isRequired,
});
