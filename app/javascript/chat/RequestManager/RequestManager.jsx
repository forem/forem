import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import { addSnackbarItem } from '../../Snackbar';
import {
  getChannelRequestInfo,
  updateMembership,
} from '../actions/requestActions';
import HeaderSection from './HeaderSection';
import ChannelRequestSection from './ChannelRequestSection';
import PersonalInvitations from './PersonalInvitationSection';

export default class RequestManager extends Component {
  static propTypes = {
    resource: PropTypes.shape({
      data: PropTypes.object,
    }).isRequired,
    activeMembershipId: PropTypes.number.isRequired,
    handleRequestRejection: PropTypes.func.isRequired,
    handleRequestApproval: PropTypes.func.isRequired,
  };

  constructor(props) {
    super(props);

    this.state = {
      requests: props.resource,
      activeMembershipId: props.activeMembershipId,
      handleRequestRejection: props.handleRequestRejection,
      handleRequestApproval: props.handleRequestApproval,
      channelJoiningRequests: [],
      userInvitations: [],
    };
  }

  componentWillReceiveProps() {
    this.setState({
      requests: this.props.resource,
      handleRequestRejection: this.props.handleRequestRejection,
      handleRequestApproval: this.props.handleRequestApproval,
      activeMembershipId: this.props.activeMembershipId,
    });
  }

  componentDidMount() {
    const { activeMembershipId } = this.props;

    getChannelRequestInfo(activeMembershipId).then((response) => {
      const { result } = response;
      const { user_joining_requests, channel_joining_memberships } = result;
      this.setState({
        channelJoiningRequests: channel_joining_memberships,
        userInvitations: user_joining_requests,
      });
    });
  }

  handleIUpdateMembership = async (e) => {
    const { membershipId, userAction } = e.target.dataset;
    const response = await updateMembership(membershipId, userAction);
    const { success, membership, message } = response;

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

      addSnackbarItem({ message });
    } else {
      addSnackbarItem({ message });
    }
  };

  render() {
    const {
      handleRequestRejection,
      handleRequestApproval,
      channelJoiningRequests,
      userInvitations,
    } = this.state;

    return (
      <div className="activechatchannel__activeArticle activesendrequest">
        <div className="p-4">
          <HeaderSection />
          <ChannelRequestSection
            channelRequests={channelJoiningRequests}
            handleRequestRejection={handleRequestRejection}
            handleRequestApproval={handleRequestApproval}
          />
          <PersonalInvitations
            userInvitations={userInvitations}
            updateMembership={this.handleIUpdateMembership}
          />
        </div>
      </div>
    );
  }
}
