import { h, Component, render } from 'preact';
import PropTypes from 'prop-types';

import {
  getChannelDetails,
  updatePersonalChatChannelNotificationSettings,
  rejectChatChannelJoiningRequest,
  acceptChatChannelJoiningRequest,
  updateChatChannelDescription,
  sendChatChannelInvitation,
  leaveChatChannelMembership,
} from '../actions/chat_channel_setting_actions';

import { Snackbar, addSnackbarItem } from '../../Snackbar';
import ModSection from './ModSection';
import PersonalSettings from './PersonalSetting';
import LeaveMembershipSection from './LeaveMembershipSection';
import ModFaqSection from './ModFaqSection';
import ChannelDescriptionSection from './ChannelDescriptionSection';
import ChatChannelMembershipSection from './ChatChannelMembershipSection';

const snackZone = document.getElementById('snack-zone');

render(<Snackbar lifespan="3" />, snackZone, null);

export default class ChatChannelSettings extends Component {
  static propTypes = {
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
      activeMembershipId: props.activeMembershipId,
      channelDescription: null,
      channelDiscoverable: null,
      invitationUsernames: null,
      showGlobalBadgeNotification: null,
    };
  }

  componentDidMount() {
    const { activeMembershipId } = this.state;

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
  }

  handleDescriptionChange = (e) => {
    const description = e.target.value;
    this.setState({
      channelDescription: description,
    });
  };

  handlePersonChatChennelSetting = (e) => {
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
      this.componentDidMount();
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

  handleChatChannelInvitations = async () => {
    const { invitationUsernames, chatChannel } = this.state;
    const { id } = chatChannel;
    const response = await sendChatChannelInvitation(id, invitationUsernames);
    const { message } = response;
    if (response.success) {
      this.componentDidMount();
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

  handleleaveChatChannelMembership = async () => {
    // eslint-disable-next-line no-restricted-globals
    const actionStatus = confirm(
      'Are you absolutely sure you want to leave this channel? This action is permanent.',
    );
    const { currentMembership } = this.state;
    if (actionStatus) {
      const response = await leaveChatChannelMembership(currentMembership.id);
      if (response.success) {
        this.componentDidMount();
      } else {
        this.setState({
          successMessages: null,
          errorMessages: response.message,
        });
      }
    }
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
    } = this.state;

    if (!chatChannel) {
      return null;
    }

    return (
      <div className="activechatchannel__activeArticle channel_settings">
        <div className="p-4">
          <ChannelDescriptionSection
            channelName={chatChannel.name}
            channelDescription={chatChannel.description}
            currentMembershipRole={currentMembership.role}
          />
          <ChatChannelMembershipSection
            currentMembershipRole={currentMembership.role}
            activeMemberships={activeMemberships}
            removeMembership={this.removeMembership}
            pendingMemberships={pendingMemberships}
            requestedMemberships={requestedMemberships}
            chatChannelAcceptMembership={this.chatChannelAcceptMembership}
          />
          <ModSection
            invitationUsernames={invitationUsernames}
            handleInvitationUsernames={this.handleInvitationUsernames}
            handleChatChannelInvitations={this.handleChatChannelInvitations}
            channelDescription={channelDescription}
            handleDescriptionChange={this.handleDescriptionChange}
            channelDiscoverable={channelDiscoverable}
            handleChannelDiscoverableStatus={
              this.handleChannelDiscoverableStatus
            }
            handleChannelDescriptionChanges={
              this.handleChannelDescriptionChanges
            }
            currentMembershipRole={currentMembership.role}
          />
          <PersonalSettings
            updateCurrentMembershipNotificationSettings={
              this.updateCurrentMembershipNotificationSettings
            }
            showGlobalBadgeNotification={showGlobalBadgeNotification}
            handlePersonChatChennelSetting={this.handlePersonChatChennelSetting}
          />
          <LeaveMembershipSection
            currentMembershipRole={currentMembership.role}
            handleleaveChatChannelMembership={
              this.handleleaveChatChannelMembership
            }
          />
          <ModFaqSection currentMembershipRole={currentMembership.role} />
        </div>
      </div>
    );
  }
}
