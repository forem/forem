import { h } from 'preact';
import PropTypes from 'prop-types';

const RequestManager = ({ resource: data }) => {
  return (
    <div className="activechatchannel__activeArticle activesendrequest">
      <div className="request_manager_header crayons-card mb-6 grid grid-flow-row gap-6 p-6">
        <h1>Joining Request</h1>
        <h3>Manage request comming to all the channels</h3>
        {data.map((request) => (
          <div className="crayons-field">
            <h1>{request.channel_name}</h1>
            <div className="request-card">
              <p>{request.member_name}</p>
              <div className="action">
                <button
                  type="button"
                  className="crayons-btn  crayons-btn--s crayons-btn--danger"
                >
                  {' '}
                  Reject
                </button>
                <button type="button" className="crayons-btn crayons-btn--s">
                  {' '}
                  Accept
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

RequestManager.propTypes = {
  resource: PropTypes.shape({
    data: PropTypes.object,
  }).isRequired,
};
export default RequestManager;
