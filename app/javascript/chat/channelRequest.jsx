import { h } from 'preact';
import PropTypes from 'prop-types';

const ChannelRequest = ({ resource: data, handleJoiningRequest }) => (
  <div className="activechatchannel__activeArticle activesendrequest">
    <div className="joining-message">
      <h2>Hey {data.user.name} !</h2>
      <h3>You are not a member of this group yet. Send request to join.</h3>
    </div>
    <div className="user-picture">
      <div className="chatmessage__profilepic">
        <img
          role="presentation"
          className="chatmessagebody__profileimage"
          src={data.user.profile_image_90}
          alt={`${data.user.username} profile`}
        />
        <img
          role="presentation"
          className="chatmessagebody__profileimage"
          src="/assets/organization.svg"
          alt={`${data.channel.name} profile`}
        />
      </div>
    </div>
    <div className="send-request">
      {data.channel.status !== 'joining_request' ? (
        <button
          type="button"
          className="cta"
          onClick={handleJoiningRequest}
          data-channel-id={data.channel.id}
        >
          {' '}
          Join {data.channel.name}{' '}
        </button>
      ) : (
        <button type="button" className="cta">
          {' '}
          Requested Already{' '}
        </button>
      )}
    </div>
  </div>
);

ChannelRequest.propTypes = {
  resource: PropTypes.shape({
    data: PropTypes.object,
  }).isRequired,
  handleJoiningRequest: PropTypes.func.isRequired,
};
export default ChannelRequest;
