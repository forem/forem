import { h } from 'preact';
import PropTypes from 'prop-types';

const RequestManager = ({
  resource: data,
  handleRequestRejection,
  handleRequestApproval,
}) => {
  return (
    <div className="activechatchannel__activeArticle activesendrequest">
      <div className="p-4">
        <div className="request_manager_header crayons-card mb-6 grid grid-flow-row gap-6 p-6">
          <h1>
            Request Center{' '}
            <span role="img" aria-label="handshake">
              🤝
            </span>
          </h1>
        </div>
        {data.map((request) => (
          <div className="crayons-card mb-6">
            <div className="crayons-card__body channel-request-card">
              <div className="requestMessage">
                <b>{request.member_name}</b> wanted to join{' '}
                <b>{request.channel_name}</b>
              </div>
              <div className="action">
                <button
                  type="button"
                  className="crayons-btn  crayons-btn--s crayons-btn--danger"
                  onClick={handleRequestRejection}
                  data-channel-id={request.id}
                  data-membership-id={request.membership_id}
                >
                  {' '}
                  Reject
                </button>
                <button
                  type="button"
                  className="crayons-btn crayons-btn--s"
                  onClick={handleRequestApproval}
                  data-channel-id={request.id}
                  data-membership-id={request.membership_id}
                >
                  {' '}
                  Accept
                </button>
              </div>
            </div>
          </div>
        ))}
        <div className="crayons-card mb-6">
          <div className="crayons-card__body channel-request-card">
            <div className="requestMessage">
              You got invitation to join <b>GroupName</b>.
            </div>
            <div className="action">
              <button
                type="button"
                className="crayons-btn  crayons-btn--s crayons-btn--danger"
                onClick={handleRequestRejection}
              >
                {' '}
                Reject
              </button>
              <button
                type="button"
                className="crayons-btn crayons-btn--s"
                onClick={handleRequestApproval}
              >
                {' '}
                Accept
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

RequestManager.propTypes = {
  resource: PropTypes.shape({
    data: PropTypes.object,
  }).isRequired,
  handleRequestRejection: PropTypes.func.isRequired,
  handleRequestApproval: PropTypes.func.isRequired,
};
export default RequestManager;
