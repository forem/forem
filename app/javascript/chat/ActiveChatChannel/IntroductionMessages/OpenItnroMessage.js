import { h } from 'preact';
import PropTypes from 'prop-types';

function OpenItnroMessage({ activeChannel }) {
  return (
    <div className="chatmessage" style={{ color: 'grey' }}>
      <div className="chatmessage__body">
        {` You have joined ${activeChannel.channel_name}! All interactions `}
        <em>
          <b>must</b>
        </em>
        {' abide by the '} <a href="/code-of-conduct">code of conduct</a>.
      </div>
    </div>
  );
}

OpenItnroMessage.propTypes = {
  activeChannel: PropTypes.object,
};

export default OpenItnroMessage;
