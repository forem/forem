import { h } from 'preact';
import PropTypes from 'prop-types';

const RequestListItem = ({ request, updateMembership }) => {
  return (
    <div className="crayons-card mb-6">
      <div className="crayons-card__body channel-request-card">
        <div className="requestMessage">
          You got invitation to join <b>{request.chat_channel_name}</b>.
        </div>
        <div className="action">
          <button
            type="button"
            className="crayons-btn  crayons-btn--s crayons-btn--danger"
            onClick={updateMembership}
            data-channel-id={request.chat_channel_id}
            data-membership-id={request.membership_id}
            data-user-action="reject"
          >
            {' '}
            Reject
          </button>
          <button
            type="button"
            className="crayons-btn crayons-btn--s"
            onClick={updateMembership}
            data-channel-id={request.chat_channel_id}
            data-membership-id={request.membership_id}
            data-user-action="accept"
          >
            {' '}
            Accept
          </button>
        </div>
      </div>
    </div>
  );
};

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
  updateMembership: PropTypes.func.isRequired,
};

export default RequestListItem;
