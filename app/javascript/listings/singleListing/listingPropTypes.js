import PropTypes from 'prop-types';

export const listingPropTypes = PropTypes.shape({
  id: PropTypes.number,
  category: PropTypes.string,
  contact_via_connect: PropTypes.bool,
  location: PropTypes.string,
  processed_html: PropTypes.string,
  slug: PropTypes.string,
  title: PropTypes.string,
  user_id: PropTypes.number,
  tag_list: PropTypes.arrayOf(PropTypes.string),
  author: PropTypes.shape({
    name: PropTypes.string.isRequired,
    username: PropTypes.string.isRequired,
    profile_image_90: PropTypes.string.isRequired,
  }),
});
