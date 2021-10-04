import { h } from 'preact';
import PropTypes from 'prop-types';
import { i18next } from '@utilities/locale';
import { Button } from '@crayons';

export const ChannelRequest = ({ resource: data, handleJoiningRequest }) => (
  <div>
    <div className="joining-message">
      <h2>{i18next.t('chat.join.message1', { user: data.user.name })}</h2>
      <h3>{i18next.t('chat.join.message2')}</h3>
    </div>
    <div className="user-picture">
      <div className="chatmessage__profilepic">
        <img
          className="chatmessagebody__profileimage"
          src={data.user.profile_image_90}
          alt={`${data.user.username} profile`}
        />
        <img
          className="chatmessagebody__profileimage"
          src="/assets/organization.svg"
          alt={`${data.channel.name} profile`}
        />
      </div>
    </div>
    <div className="send-request">
      {data.channel.status !== 'joining_request' ? (
        <Button
          variant="primary"
          onClick={handleJoiningRequest}
          data-channel-id={data.channel.id}
        >
          {i18next.t('chat.join.request', { channel: data.channel.name })}
        </Button>
      ) : (
        <Button variant="secondary">{i18next.t('chat.join.requested')}</Button>
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
