import PropTypes from 'prop-types';

export const defaultChannelPropTypes = PropTypes.shape({
  channel: PropTypes.shape({
    channel_name: PropTypes.string,
    channel_color: PropTypes.string,
    channel_type: PropTypes.string,
    channel_modified_slug: PropTypes.string,
    id: PropTypes.number,
    chat_channel_id: PropTypes.number,
    status: PropTypes.string,
    channel_image: PropTypes.string,
  }).isRequired,
});
