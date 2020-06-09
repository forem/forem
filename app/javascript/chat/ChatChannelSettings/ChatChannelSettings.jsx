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

    this.handleDescriptionChange = (e) => {
      const description = e.target.value;

      this.setState({
        channelDescription: description,
      });
    };

    this.handlePersonChatChennelSetting = (e) => {
      const status = e.target.checked;

      this.setState({
        showGlobalBadgeNotification: status,
      });
    };

    this.updateCurrentMembershipNotificationSettings = async () => {
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

    this.chatChannelRemoveMembership = async (
      membershipId,
      membershipStatus,
    ) => {
      const response = await rejectChatChannelJoiningRequest(
        chatChannel.id,
        membershipId,
        membershipStatus,
      );
      return response;
    };

    this.removeActiveMembership = async (e) => {
      const { membershipId, membershipStatus } = e.target.dataset;
      const response = await this.chatChannelRemoveMembership(
        membershipId,
        membershipStatus,
      );

      const { message } = response;

      if (response.success) {
        this.setState((prevState) => {
          const filterActiveMemberships = prevState.activeMemberships.filter(
            (activeMembership) =>
              activeMembership.membership_id !== Number(membershipId),
          );

          return {
            errorMessages: null,
            successMessages: response.message,
            activeMemberships: filterActiveMemberships,
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

    this.removePendingMembership = async (e) => {
      const { membershipId, membershipStatus } = e.target.dataset;
      const response = await this.chatChannelRemoveMembership(
        membershipId,
        membershipStatus,
      );
      const { message } = response;

      if (response.success) {
        this.setState((prevState) => {
          const filterPendingMemberships = prevState.pendingMemberships.filter(
            (pendingMembership) =>
              pendingMembership.membership_id !== Number(membershipId),
          );

          return {
            errorMessages: null,
            successMessages: response.message,
            pendingMemberships: filterPendingMemberships,
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

    this.removeRequestedMembership = async (e) => {
      const { membershipId, membershipStatus } = e.target.dataset;
      const response = await this.chatChannelRemoveMembership(
        membershipId,
        membershipStatus,
      );
      const { message } = response;

      if (response.success) {
        this.setState((prevState) => {
          const filterRequestedMemberships = prevState.requestedMemberships.filter(
            (requestedMembership) =>
              requestedMembership.membership_id !== Number(membershipId),
          );

          return {
            errorMessages: null,
            successMessages: response.message,
            requestedMemberships: filterRequestedMemberships,
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

    this.chatChannelAcceptMembership = async (e) => {
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

    this.handleChannelDiscoverableStatus = (e) => {
      const status = e.target.checked;

      this.setState({
        channelDiscoverable: status,
      });
    };

    this.handleChannelDescriptionChanges = async () => {
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

    this.handleInvitationUsernames = (e) => {
      const invitationUsernameValue = e.target.value;

      this.setState({
        invitationUsernames: invitationUsernameValue,
      });
    };

    this.handleChatChannelInvitations = async () => {
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

    this.handleleaveChatChannelMembership = async () => {
      // eslint-disable-next-line no-restricted-globals
      const actionStatus = confirm(
        'Are you absolutely sure you want to leave this channel? This action is permanent.',
      );

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
            removeActiveMembership={this.removeActiveMembership}
            pendingMemberships={pendingMemberships}
            requestedMemberships={requestedMemberships}
            removePendingMembership={this.removePendingMembership}
            removeRequestedMembership={this.removeRequestedMembership}
            chatChannelAcceptMembership={this.chatChannelAcceptMembership}
          />
          <div>
            <ModSection 
              invitationUsernames={invitationUsernames}
              handleInvitationUsernames={this.handleInvitationUsernames}
              handleChatChannelInvitations={this.handleChatChannelInvitations}
              channelDescription={channelDescription}
              handleDescriptionChange={this.handleDescriptionChange}
              channelDiscoverable={channelDiscoverable}
              handleChannelDiscoverableStatus={this.handleChannelDiscoverableStatus}
              handleChannelDescriptionChanges={this.handleChannelDescriptionChanges}
              currentMembershipRole={currentMembership.role}
            />
          </div>
          <PersonalSettings 
            updateCurrentMembershipNotificationSettings={this.updateCurrentMembershipNotificationSettings}
            showGlobalBadgeNotification={showGlobalBadgeNotification}
            handlePersonChatChennelSetting={this.handlePersonChatChennelSetting}
          />
          <LeaveMembershipSection
            currentMembershipRole={currentMembership.role}
            handleleaveChatChannelMembership={this.handleleaveChatChannelMembership}
          />
          <ModFaqSection currentMembershipRole={currentMembership.role} />
        </div>
      </div>
    );
  }
}
