import { h } from 'preact';
import PropTypes from 'prop-types';

/**
 * This component is used to render the DirectIntroMessages for direct conversations
 *
 * @param {object} props
 * @param {object} props.activeChannel
 *
 *
 * @component
 *
 * @example
 *
 * <DireactIntroMessages activeChannel={activeChannel} />
 *
 */
function DireactIntroMessages({ activeChannel }) {
  return (
    <div className="chatmessage" style={{ color: 'grey' }}>
      <div className="chatmessage__body">
        {'You and '}
        <a href={`/${activeChannel.channel_modified_slug}`}>
          {activeChannel.channel_modified_slug}
        </a>
        {' are connected because you both follow each other. All interactions '}
        <em className="fw-bold">must</em>
        {' abide by the '}
        <a href="/code-of-conduct">code of conduct</a>.
      </div>
    </div>
  );
}

DireactIntroMessages.propTypes = {
  activeChannel: PropTypes.object,
};

export default DireactIntroMessages;
