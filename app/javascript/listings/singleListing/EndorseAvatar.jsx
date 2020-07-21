import PropTypes from 'prop-types';
import { h } from 'preact';

const EndorseAvatar = ({ avatar }) => {
  return <img src={avatar} width={40} height={40} alt="end_img" />;
};

EndorseAvatar.propTypes = {
  avatar: PropTypes.string.isRequired,
};

export default EndorseAvatar;
