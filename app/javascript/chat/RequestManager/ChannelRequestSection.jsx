import { h } from 'preact';
import PropTypes from 'prop-types';
import RequestListItem from './RequestListItem';

/**
 *
 * This component is used to render the Channel request section
 *
 * @param {object} props
 * @param {array} props.channelRequests
 * @param {function} props.handleRequestApproval
 * @param {function} props.handleRequestRejection
 *
 * @component
 *
 * @example
 *
 * <ChannelRequestSection
 *  channelRequests={channelRequests}
 *  handleRequestApproval={handleRequestApproval}
 *  handleRequestRejection={handleRequestRejection}
 * />
 *
 */

export default function ChannelRequestSection({
  channelRequests,
  handleRequestApproval,
  handleRequestRejection,
}) {
  if (channelRequests.length < 0) {
    return null;
  }

  return (
    <div
      data-testid="chat-channel-joining-request"
      data-active-count={channelRequests ? channelRequests.length : 0}
    >
      {channelRequests &&
        channelRequests.map((channelPendingRequest) => {
          return (
            <RequestListItem
              request={channelPendingRequest}
              handleRequestApproval={handleRequestApproval}
              handleRequestRejection={handleRequestRejection}
            />
          );
        })}
    </div>
  );
}

ChannelRequestSection.propTypes = {
  channelRequests: PropTypes.arrayOf(
    PropTypes.shape({
      name: PropTypes.string.isRequired,
      membership_id: PropTypes.number.isRequired,
      user_id: PropTypes.number.isRequired,
      role: PropTypes.string.isRequired,
      image: PropTypes.string.isRequired,
      username: PropTypes.string.isRequired,
      status: PropTypes.string.isRequired,
      channel_name: PropTypes.string.isRequired,
    }),
  ).isRequired,
  handleRequestApproval: PropTypes.func.isRequired,
  handleRequestRejection: PropTypes.func.isRequired,
};
