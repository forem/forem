import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import { addSnackbarItem } from '../../Snackbar';
import {
  getChannelRequestInfo,
  updateMembership,
  acceptJoiningRequest,
  rejectJoiningRequest,
} from '../actions/requestActions';
import { HeaderSection } from './HeaderSection';
import { ChannelRequestSection } from './ChannelRequestSection';
import { PersonalInvitationSection } from './PersonalInvitationSection';

export class RequestManager extends Component {
  static propTypes = {
    resource: PropTypes.shape({
      data: PropTypes.object,
    }).isRequired,
    updateRequestCount: PropTypes.func.isRequired,
  };

  constructor(props) {
    super(props);

    this.state = {
      updateRequestCount: props.updateRequestCount,
      channelJoiningRequests: [],
      userInvitations: [],
    };
  }

  componentWillReceiveProps() {
    this.setState({
      updateRequestCount: this.props.updateRequestCount,
    });
  }

  componentDidMount() {
    getChannelRequestInfo().then((response) => {
      const { result } = response;
      const { user_joining_requests, channel_joining_memberships } = result;
      this.setState({
        channelJoiningRequests: channel_joining_memberships,
        userInvitations: user_joining_requests,
      });
    });
  }

  handleIUpdateMembership = async (e) => {
    const {
      membershipId,
      userAction,
      channelSlug,
      channelId,
    } = e.target.dataset;
    const response = await updateMembership(membershipId, userAction);
    const { success, membership, message } = response;
    const { updateRequestCount } = this.state;
    if (success) {
      this.setState((prevState) => {
        const filteredUserInvitations = prevState.userInvitations.filter(
          (userInvitation) =>
            userInvitation.membership_id !== membership.membership_id,
        );

        return {
          userInvitations: filteredUserInvitations,
        };
      });
      if (userAction === 'accept') {
        updateRequestCount(true, { channelSlug, channelId });
      }
      updateRequestCount();
      addSnackbarItem({ message });
    } else {
      addSnackbarItem({ message });
    }
  };

  handleAcceptJoingRequest = async (e) => {
    const { membershipId, channelId } = e.target.dataset;
    const response = await acceptJoiningRequest(channelId, membershipId);
    const { success, message, membership } = response;
    const { updateRequestCount } = this.state;

    if (success) {
      this.setState((prevState) => {
        const formattedChannelJoiningRequests = prevState.channelJoiningRequests.filter(
          (channelJoiningRequest) =>
            channelJoiningRequest.membership_id !== membership.membership_id,
        );
        return {
          channelJoiningRequests: formattedChannelJoiningRequests,
        };
      });

      updateRequestCount();
      addSnackbarItem({ message });
    } else {
      addSnackbarItem({ message });
    }
  };

  handleRejectJoingRequest = async (e) => {
    const { membershipId, channelId } = e.target.dataset;
    const response = await rejectJoiningRequest(channelId, membershipId);
    const { success, message } = response;
    const { updateRequestCount } = this.state;

    if (success) {
      this.setState((prevState) => {
        const formattedChannelJoiningRequests = prevState.channelJoiningRequests.filter(
          (channelJoiningRequest) =>
            channelJoiningRequest.membership_id !== Number(membershipId),
        );
        return {
          channelJoiningRequests: formattedChannelJoiningRequests,
        };
      });

      updateRequestCount();
      addSnackbarItem({ message });
    } else {
      addSnackbarItem({ message });
    }
  };

  render() {
    const { channelJoiningRequests, userInvitations } = this.state;

    return (
      <div>
        <div className="p-4">
          <HeaderSection />
          {channelJoiningRequests.length <= 0 && userInvitations.length <= 0 ? (
            <p>You have no pending invitations/Joining Requests.</p>
          ) : null}
          <ChannelRequestSection
            channelRequests={channelJoiningRequests}
            handleRequestRejection={this.handleRejectJoingRequest}
            handleRequestApproval={this.handleAcceptJoingRequest}
          />
          <PersonalInvitationSection
            userInvitations={userInvitations}
            updateMembership={this.handleIUpdateMembership}
          />
        </div>
      </div>
    );
  }
}
