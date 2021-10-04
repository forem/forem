import { h } from 'preact';
import { useState } from 'preact/hooks';
import PropTypes from 'prop-types';
import { createChannel } from '../actions/chat_channel_setting_actions';
import { addSnackbarItem } from '../../Snackbar';
import { Modal, Button } from '@crayons';

/**
 *
 * This component is used to create a chat channel. At the moment only  support for tag_moderator user types.
 *
 * @param {object} props
 * @param {function} props.toggleModalCreateChannel
 * @param {function} props.handleCreateChannelSuccess
 *
 * @component
 *
 * @example
 *
 * <CreateChatModal
 *   toggleModalCreateChannel={toggleModalCreateChannel}
 *   handleCreateChannelSuccess={handleCreateChannelSuccess}
 * />
 *
 */

export function CreateChatModal({
  toggleModalCreateChannel,
  handleCreateChannelSuccess,
}) {
  const [channelName, setchannelName] = useState(undefined);
  const [userNames, setUserNames] = useState(undefined);

  const handleCreateChannel = async (e) => {
    e.preventDefault();
    const result = await createChannel(channelName, userNames);
    if (result.success) {
      handleCreateChannelSuccess();
      addSnackbarItem({ message: result.message });
    } else {
      addSnackbarItem({ message: result.message });
    }
  };

  return (
    <Modal
      title={i18next.t('chat.create.title')}
      size="s"
      onClose={toggleModalCreateChannel}
    >
      <div className="crayons-field">
        <label htmlFor="t1" className="crayons-field__label">
          {i18next.t('chat.create.name')}
        </label>
        <input
          type="text"
          id="t1"
          className="crayons-textfield"
          placeholder={i18next.t('chat.create.enter')}
          value={channelName}
          onInput={(e) => setchannelName(e.target.value)}
        />
        <label htmlFor="t2" className="crayons-field__label">
          {i18next.t('chat.create.invite')}
        </label>
        <input
          type="text"
          id="t2"
          className="crayons-textfield"
          placeholder={i18next.t('chat.create.users')}
          value={userNames}
          onInput={(e) => setUserNames(e.target.value)}
        />

        <Button
          className="crayons-btn"
          onClick={handleCreateChannel}
          style="margin-top:20px"
          disabled={!channelName}
        >
          {i18next.t('chat.create.submit')}
        </Button>
      </div>
    </Modal>
  );
}

CreateChatModal.propTypes = {
  toggleModalCreateChannel: PropTypes.func.isRequired,
  handleCreateChannelSuccess: PropTypes.func.isRequired,
};
