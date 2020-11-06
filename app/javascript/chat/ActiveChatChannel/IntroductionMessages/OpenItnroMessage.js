import { h } from 'preact';
import PropTypes from 'prop-types';

/**
 * This component is used to render the Open intro messages for direct conversations
 *
 * @param {object} props
 * @param {object} props.activeChannel
 *
 *
 * @component
 *
 * @example
 *
 * <IntroductionMessage activeChannel={activeChannel} />
 *
 */

function IntroductionMessage({ activeChannel }) {
  return (
    <div className="chatmessage" style={{ color: 'grey' }}>
      <div className="chatmessage__body">
        {` You have joined ${activeChannel.channel_name}! All interactions `}
        <em className="fw-bold">must</em>
        {' abide by the '} <a href="/code-of-conduct">code of conduct</a>.
      </div>
    </div>
  );
}

IntroductionMessage.propTypes = {
  activeChannel: PropTypes.object,
};

export default IntroductionMessage;
