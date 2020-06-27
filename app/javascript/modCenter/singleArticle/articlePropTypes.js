import PropTypes from 'prop-types';

export default PropTypes.shape({
  id: PropTypes.number,
  title: PropTypes.string,
  path: PropTypes.string,
  cached_tag_list: PropTypes.arrayOf(PropTypes.string),
  user: PropTypes.shape({
    name: PropTypes.string.isRequired,
    username: PropTypes.string.isRequired,
    path: PropTypes.string.isRequired,
  }),
});
