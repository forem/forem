import { h } from 'preact';
import PropTypes from 'prop-types';

const ChannelSetting = ({ resource: data }) => {
  return (
    <div className="activechatchannel__activeArticle">
      <div className="p-4">
        <div className="p-4 grid gap-2 crayons-card mb-4 channel_details">
          <h1 className="mb-1">Sarthak-test</h1>
          <p>
            Lorem ipsum dolor sit amet consectetur, adipisicing elit. Et natus
            error illum nesciunt recusandae autem odio expedita impedit atque.
            Voluptatibus.
          </p>
          <p className="fw-bold">You are a channel mod</p>
        </div>
        <div className="p-4 grid gap-2 crayons-card mb-4">
          <h3 className="mb-2">Members</h3>
        </div>
        <div className="p-4 grid gap-2 crayons-card mb-4">
          <h3 className="mb-2">Pending Invitations</h3>
        </div>
        <div className="p-4 grid gap-2 crayons-card mb-4">
          <h3 className="mb-2">Joining Request</h3>
        </div>
        <div className="crayons-card p-4 grid gap-2 mb-4">
          <div className="crayons-field">
            <label
              className="crayons-field__label"
              for="chat_channel_membership_Usernames to Invite"
            >
              Usernames to invite
            </label>
            <input
              placeholder="Comma separated"
              className="crayons-textfield"
              type="text"
              name="chat_channel_membership[invitation_usernames]"
              id="chat_channel_membership_invitation_usernames"
            />
          </div>
        </div>
        <div className="crayons-card p-4 grid gap-2 mb-4">
          <h3>Channel Settings</h3>
          <div className="crayons-field">
            <label
              className="crayons-field__label"
              for="chat_channel_description"
            >
              Description
            </label>
            <textarea
              className="crayons-textfield"
              name="chat_channel[description]"
              id="chat_channel_description"
            ></textarea>
          </div>
          <div>
            <button class="crayons-btn">Submit</button>
          </div>
        </div>
        <div className="crayons-card p-4 grid gap-2 mb-4">
          <h3>Personal Settings</h3>
          <h4>Notifications</h4>
          <div className="crayons-field crayons-field--checkbox">
            <input type="checkbox" id="c2" className="crayons-checkbox" />
            <label for="c2" className="crayons-field__label">
              Receive Notifications for New Messages
            </label>
          </div>
          <div>
            <button class="crayons-btn">Submit</button>
          </div>
        </div>
        <div className="crayons-card grid gap-2 p-4">
          <p>
            Questions about Connect Channel moderation? Contact{' '}
            <a
              href="mailto:yo@dev.to"
              target="_blank"
              rel="noopener noreferrer"
            >
              yo@dev.to
            </a>
          </p>
        </div>
      </div>
    </div>
  );
};

ChannelSetting.propTypes = {
  resource: PropTypes.shape({
    data: PropTypes.object,
  }).isRequired,
};
export default ChannelSetting;
