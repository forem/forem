import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import {
  getChannelDetails,
  updatePersonalChatChannelNotificationSettings,
  rejectChatChannelJoiningRequest,
  acceptChatChannelJoiningRequest,
  updateChatChannelDescription,
  sendChatChannelInvitation,
  leaveChatChannelMembership,
  updateMembershipRole,
} from '../actions/chat_channel_setting_actions';

import { addSnackbarItem } from '../../Snackbar';
import { ManageActiveMembership } from './MembershipManager/ManageActiveMembership';
import { ChatChannelSettingsSection } from './ChatChannelSettingsSection';

export class ChatChannelSettings extends Component {
  static propTypes = {
    handleLeavingChannel: PropTypes.func.isRequired,
    activeMembershipId: PropTypes.number.isRequired,
  };

  constructor(props) {
    super(props);

    this.state = {
      successMessages: null,
      errorMessages: null,
      activeMemberships: [],
      pendingMemberships: [],
      requestedMemberships: [],
      chatChannel: null,
      currentMembership: null,
      activeMembershipId: null,
      channelDescription: null,
      channelDiscoverable: null,
      invitationUsernames: null,
      showGlobalBadgeNotification: null,
      displaySettings: true,
      displayMembershipManager: false,
      invitationLink: null,
    };
  }

  componentDidMount() {
    this.updateChannelDetails();
  }

  componentWillReceiveProps() {
    const { activeMembershipId } = this.props;
    this.setState({
      activeMembershipId,
    });
  }

  updateChannelDetails = () => {
    const { activeMembershipId } = this.props;

    getChannelDetails(activeMembershipId)
      .then((response) => {
        if (response.success) {
          const { result } = response;
          this.setState({
            chatChannel: result.chat_channel,
            activeMemberships: result.memberships.active,
            pendingMemberships: result.memberships.pending,
            requestedMemberships: result.memberships.requested,
            currentMembership: result.current_membership,
            channelDescription: result.chat_channel.description,
            channelDiscoverable: result.chat_channel.discoverable,
            showGlobalBadgeNotification:
              result.current_membership.show_global_badge_notification,
            invitationLink: result.invitation_link,
          });
        } else {
          this.setState({
            successMessages: null,
            errorMessages: response.message,
          });
        }
      })
      .catch((error) => {
        this.setState({
          successMessages: null,
          errorMessages: error.message,
        });
      });
  };

  handleDescriptionChange = (e) => {
    const description = e.target.value;
    this.setState({
      channelDescription: description,
    });
  };

  handlePersonChannelSetting = (e) => {
    const status = e.target.checked;
    this.setState({
      showGlobalBadgeNotification: status,
    });
  };

  updateCurrentMembershipNotificationSettings = async () => {
    const { currentMembership, showGlobalBadgeNotification } = this.state;
    const response = await updatePersonalChatChannelNotificationSettings(
      currentMembership.id,
      showGlobalBadgeNotification,
    );
    const { message } = response;
    if (response.success) {
      this.setState((prevState) => {
        return {
          errorMessages: null,
          successMessages: response.message,
          currentMembership: {
            ...prevState.currentMembership,
            show_global_badge_notification: showGlobalBadgeNotification,
          },
        };
      });
    } else {
      this.setState({
        successMessages: null,
        errorMessages: response.message,
        showGlobalBadgeNotification:
          currentMembership.show_global_badge_notification,
      });
    }
    addSnackbarItem({ message });
  };

  chatChannelRemoveMembership = async (membershipId, membershipStatus) => {
    const { chatChannel } = this.state;
    const response = await rejectChatChannelJoiningRequest(
      chatChannel.id,
      membershipId,
      membershipStatus,
    );
    return response;
  };

  filterMemberships = (memberships, membershipId) => {
    const filteredMembership = memberships.filter(
      (membership) => membership.membership_id !== Number(membershipId),
    );
    return filteredMembership;
  };

  removeMembership = async (e) => {
    const { membershipId, membershipStatus } = e.target.dataset;
    const response = await this.chatChannelRemoveMembership(
      membershipId,
      membershipStatus,
    );
    const { message } = response;
    this.updateMemberships(membershipId, response, membershipStatus);
    addSnackbarItem({ message });
  };

  updateMemberships = (membershipId, response, membershipStatus) => {
    if (response.success) {
      this.updateChannelDetails();
      this.setState((prevState) => {
        return {
          errorMessages: null,
          successMessages: response.message,
          activeMemberships:
            membershipStatus === 'active'
              ? this.filterMemberships(
                  prevState.activeMemberships,
                  membershipId,
                )
              : prevState.activeMemberships,
          pendingMemberships:
            membershipStatus === 'pending'
              ? this.filterMemberships(
                  prevState.pendingMemberships,
                  membershipId,
                )
              : prevState.pendingMemberships,
          requestedMemberships:
            membershipStatus === 'joining_request'
              ? this.filterMemberships(
                  prevState.requestedMemberships,
                  membershipId,
                )
              : prevState.requestedMembership,
        };
      });
    } else {
      this.setState({
        successMessages: null,
        errorMessages: response.message,
      });
    }
  };

  chatChannelAcceptMembership = async (e) => {
    const { chatChannel } = this.state;
    const { membershipId } = e.target.dataset;
    const response = await acceptChatChannelJoiningRequest(
      chatChannel.id,
      membershipId,
    );
    const { message } = response;
    if (response.success) {
      this.setState((prevState) => {
        const filteredRequestedMemberships = prevState.requestedMemberships.filter(
          (requestedMembership) =>
            requestedMembership.membership_id !== Number(membershipId),
        );
        const updatedActiveMembership = [
          ...prevState.activeMemberships,
          response.membership,
        ];
        return {
          errorMessages: null,
          successMessages: response.message,
          requestedMemberships: filteredRequestedMemberships,
          activeMemberships: updatedActiveMembership,
        };
      });
    } else {
      this.setState({
        successMessages: null,
        errorMessages: response.message,
      });
    }
    addSnackbarItem({ message });
  };

  handleChannelDiscoverableStatus = (e) => {
    const status = e.target.checked;
    this.setState({
      channelDiscoverable: status,
    });
  };

  handleChannelDescriptionChanges = async () => {
    const { chatChannel, channelDescription, channelDiscoverable } = this.state;
    const { id } = chatChannel;
    const response = await updateChatChannelDescription(
      id,
      channelDescription,
      channelDiscoverable,
    );
    const { message } = response;

    if (response.success) {
      this.updateChannelDetails();
      this.setState((prevState) => {
        return {
          errorMessages: null,
          successMessages: response.message,
          chatChannel: {
            ...prevState,
            description: channelDescription,
            discoverable: channelDiscoverable,
          },
        };
      });
    } else {
      this.setState({
        successMessages: null,
        errorMessages: response.message,
        channelDiscoverable: chatChannel.discoverable,
      });
    }
    addSnackbarItem({ message });
  };

  handleInvitationUsernames = (e) => {
    const invitationUsernameValue = e.target.value;
    this.setState({
      invitationUsernames: invitationUsernameValue,
    });
  };

  handleChannelInvitations = async () => {
    const { invitationUsernames, chatChannel } = this.state;
    const { id } = chatChannel;
    const response = await sendChatChannelInvitation(id, invitationUsernames);
    const { message } = response;
    if (response.success) {
      this.updateChannelDetails();
      this.setState({
        errorMessages: null,
        successMessages: response.message,
        invitationUsernames: null,
      });
    } else {
      this.setState({
        successMessages: null,
        errorMessages: response.message,
      });
    }
    addSnackbarItem({ message });
  };

  handleleaveChannelMembership = async () => {
    // eslint-disable-next-line no-restricted-globals
    const actionStatus = confirm(
      'Are you absolutely sure you want to leave this channel? This action is permanent.',
    );
    const { currentMembership } = this.state;
    if (actionStatus) {
      const response = await leaveChatChannelMembership(currentMembership.id);
      const { message } = response;
      if (response.success) {
        this.setState({
          successMessages: message,
          errorMessages: null,
        });
        this.props.handleLeavingChannel(currentMembership.id);
      } else {
        this.setState({
          successMessages: null,
          errorMessages: response.message,
        });
      }
      addSnackbarItem({ message });
    }
  };

  toggleScreens = () => {
    const { displaySettings, displayMembershipManager } = this.state;

    this.setState({
      displaySettings: !displaySettings,
      displayMembershipManager: !displayMembershipManager,
    });
  };

  handleUpdateMembershipRole = async (e) => {
    const { membershipId, role } = e.target.dataset;
    const { chatChannel } = this.state;
    const response = await updateMembershipRole(
      membershipId,
      chatChannel.id,
      role,
    );
    const { message } = response;
    if (response.success) {
      this.updateChannelDetails();
      this.setState((prevState) => {
        const { activeMemberships } = prevState;
        const updatedActiveMemberships = activeMemberships.map(
          (activeMembership) => {
            if (activeMembership.membership_id === Number(membershipId)) {
              return { ...activeMembership, role };
            }
            return activeMembership;
          },
        );
        return {
          ...prevState,
          activeMemberships: updatedActiveMemberships,
          errorMessages: null,
          successMessages: response.message,
        };
      });
    } else {
      this.setState({
        successMessages: null,
        errorMessages: response.message,
      });
    }

    addSnackbarItem({ message });
  };

  render() {
    const {
      chatChannel,
      currentMembership,
      activeMemberships,
      pendingMemberships,
      requestedMemberships,
      channelDescription,
      channelDiscoverable,
      invitationUsernames,
      showGlobalBadgeNotification,
      displaySettings,
      invitationLink,
    } = this.state;

    if (!chatChannel) {
      return null;
    }

    return (
      <div className="activechatchannel__activeArticle channel_settings">
        <div className="p-4">
          {displaySettings ? (
            <ChatChannelSettingsSection
              channelDiscoverable={channelDiscoverable}
              updateCurrentMembershipNotificationSettings={
                this.updateCurrentMembershipNotificationSettings
              }
              handleleaveChannelMembership={this.handleleaveChannelMembership}
              handlePersonChannelSetting={this.handlePersonChannelSetting}
              handleChannelDescriptionChanges={
                this.handleChannelDescriptionChanges
              }
              handleChannelDiscoverableStatus={
                this.handleChannelDiscoverableStatus
              }
              handleDescriptionChange={this.handleDescriptionChange}
              handleChannelInvitations={this.handleChannelInvitations}
              handleInvitationUsernames={this.handleInvitationUsernames}
              toggleScreens={this.toggleScreens}
              removeMembership={this.removeMembership}
              chatChannelAcceptMembership={this.chatChannelAcceptMembership}
              channelDescription={channelDescription}
              chatChannel={chatChannel}
              currentMembership={currentMembership}
              activeMemberships={activeMemberships}
              pendingMemberships={pendingMemberships}
              requestedMemberships={requestedMemberships}
              invitationUsernames={invitationUsernames}
              showGlobalBadgeNotification={showGlobalBadgeNotification}
            />
          ) : (
            <ManageActiveMembership
              activeMemberships={activeMemberships}
              currentMembership={currentMembership}
              chatChannel={chatChannel}
              invitationLink={invitationLink}
              removeMembership={this.removeMembership}
              handleUpdateMembershipRole={this.handleUpdateMembershipRole}
            />
          )}
        </div>
      </div>
    );
  }
}
