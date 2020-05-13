import { h } from 'preact';
import PropTypes from 'prop-types';

const RequestManager = ({ resource: data }) => (
  <div className="activechatchannel__activeArticle activesendrequest">
    <h1>titles</h1>
  </div>
);

RequestManager.propTypes = {
  resource: PropTypes.shape({
    data: PropTypes.object,
  }).isRequired,
};
export default RequestManager;
