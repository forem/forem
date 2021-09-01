import { h } from 'preact';
import PropTypes from 'prop-types';

import { Button } from '@crayons';

export const PendingInvitationListItem = ({ request, updateMembership }) => (
  <div className="crayons-card mb-6">
    <div className="crayons-card__body channel-request-card">
      <div className="request-message d-flex flex-wrap">
        You got invitation to join <b>{request.chat_channel_name}</b>.
      </div>
      <div className="request-actions">
        <Button
          className="m-2"
          size="s"
          variant="danger"
          onClick={updateMembership}
          data-channel-id={request.chat_channel_id}
          data-membership-id={request.membership_id}
          data-channel-slug={request.slug}
          data-user-action="reject"
        >
          {' '}
          Reject
        </Button>
        <Button
          className="m-2"
          size="s"
          onClick={updateMembership}
          data-channel-id={request.chat_channel_id}
          data-membership-id={request.membership_id}
          data-channel-slug={request.slug}
          data-user-action="accept"
        >
          {' '}
          Accept
        </Button>
      </div>
    </div>
  </div>
);

PendingInvitationListItem.propTypes = {
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
  updateMembership: PropTypes.func.isRequired,
};
