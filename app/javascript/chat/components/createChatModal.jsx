import { h } from 'preact';
import { useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { Modal } from '@crayons/Modal';
import { createChannel } from '../actions/chat_channel_setting_actions';
const CreateChatModal = ({
  toggleModalCreateChannel,
  handleCreateChannelSuccess,
}) => {
  const [channelName, setchannelName] = useState('');
  const [userNames, setUserNames] = useState('');

  const handleCreateChannel = async (e) => {
    e.preventDefault();
    const result = await createChannel(channelName, userNames);
    if (result.success) {
      handleCreateChannelSuccess();
    }
  };

  return (
    <Modal title="Create A Channel" size="s" onClose={toggleModalCreateChannel}>
      <div className="crayons-field">
        <label htmlFor="t1" className="crayons-field__label">
          Channel Name
        </label>
        <input
          type="text"
          id="t1"
          className="crayons-textfield"
          placeholder="Enter name here..."
          value={channelName}
          onChange={(e) => setchannelName(e.target.value)}
        />
        <label htmlFor="t2" className="crayons-field__label">
          Invite Users
        </label>
        <input
          type="text"
          id="t2"
          className="crayons-textfield"
          placeholder="Separate username with comma"
          value={userNames}
          onChange={(e) => setUserNames(e.target.value)}
        />

        <button
          href="#"
          className="crayons-btn"
          onClick={handleCreateChannel}
          style="margin-top:20px"
        >
          Create
        </button>
      </div>
    </Modal>
  );
};

CreateChatModal.propTypes = {
  toggleModalCreateChannel: PropTypes.func.isRequired,
  handleCreateChannelSuccess: PropTypes.func.isRequired,
};

export default CreateChatModal;
