import { h } from 'preact';
import PropTypes from 'prop-types';
import { Trans } from 'react-i18next';
import { i18next } from '@utilities/locale';

import { Button } from '@crayons';

export const RequestListItem = ({
  request,
  handleRequestRejection,
  handleRequestApproval,
}) => (
  <div className="crayons-card mb-6">
    <div className="crayons-card__body channel-request-card">
      <div className="request-message d-flex flex-wrap">
        <Trans i18nKey="chat.join.join" values={{name: request.name, channel: request.chat_channel_name}} />
      </div>
      <div className="request-actions">
        <Button
          className="m-2"
          variant="danger"
          size="s"
          onClick={handleRequestRejection}
          data-channel-id={request.chat_channel_id}
          data-membership-id={request.membership_id}
        >
          {i18next.t('chat.join.reject')}
        </Button>
        <Button
          className="m-2"
          size="s"
          onClick={handleRequestApproval}
          data-channel-id={request.chat_channel_id}
          data-membership-id={request.membership_id}
        >
          {i18next.t('chat.join.accept')}
        </Button>
      </div>
    </div>
  </div>
);

RequestListItem.propTypes = {
  request: PropTypes.arrayOf(
    PropTypes.shape({
      name: PropTypes.string.isRequired,
      membership_id: PropTypes.number.isRequired,
      user_id: PropTypes.number.isRequired,
      role: PropTypes.string.isRequired,
      image: PropTypes.string.isRequired,
      username: PropTypes.string.isRequired,
      status: PropTypes.string.isRequired,
      chat_channel_name: PropTypes.string.isRequired,
    }),
  ).isRequired,
  handleRequestRejection: PropTypes.func.isRequired,
  handleRequestApproval: PropTypes.func.isRequired,
};
