import { h } from 'preact';
import PropTypes from 'prop-types';

import { Button } from '@crayons';

export const RequestListItem = ({
  request,
  handleRequestRejection,
  handleRequestApproval,
}) => (
  <div className="crayons-card mb-6">
    <div className="crayons-card__body channel-request-card">
      <div className="request-message d-flex flex-wrap">
        <b>{request.name}</b> requested to join{' '}
        <b>{request.chat_channel_name}</b>
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
          Reject
        </Button>
        <Button
          className="m-2"
          size="s"
          onClick={handleRequestApproval}
          data-channel-id={request.chat_channel_id}
          data-membership-id={request.membership_id}
        >
          Accept
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
