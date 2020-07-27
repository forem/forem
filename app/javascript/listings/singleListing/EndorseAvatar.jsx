import PropTypes from 'prop-types';
import { h } from 'preact';

const EndorseAvatar = ({ avatar, content, isOpen }) => {
  const showEndorsement = isOpen
    ? 'show_full_endorsement'
    : 'show_avatar_endorsement';
  const showContent = isOpen ? 'inline' : 'none';
  return (
    <span className={showEndorsement}>
      <img src={avatar} width={40} height={40} alt="end_img" />
      <label>
        <input
          type="text"
          value={content}
          style={{ display: showContent }}
          className="endorsement_content"
        />
      </label>
    </span>
  );
};

EndorseAvatar.propTypes = {
  avatar: PropTypes.string.isRequired,
};

export default EndorseAvatar;
