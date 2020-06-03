import { h, Component, render } from 'preact';
import PropTypes from 'prop-types';

import {
  getChannelDetails,
  udatePersonalChatChannelNotificationSettings,
  rejectChatChannelJoiningRequest,
  acceptChatChannelJoiningRequest,
  updateChatChannelDescription,
  sendChatChannelInvitation,
  leaveChatChannelMembership,
} from './actions/chat_channel_setting_actions';

import { Snackbar, addSnackbarItem } from '../Snackbar';

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
      const response = await udatePersonalChatChannelNotificationSettings(
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
      <div className="activechatchannel__activeArticle">
        <div className="p-4">
          <div className="p-4 grid gap-2 crayons-card mb-4 channel_details">
            <h1 className="mb-1">{chatChannel.name}</h1>
            <p>{chatChannel.description}</p>
            <p className="fw-bold">
              You are a channel 
              {' '}
              {currentMembership.role}
            </p>
          </div>
          <div className="p-4 grid gap-2 crayons-card mb-4">
            <h3 className="mb-2">Members</h3>
            {activeMemberships && activeMemberships.length > 0
              ? activeMemberships.map((membership) => (
                <div className="flex items-center">
                  <a href={`/${membership.username}`}>
                    <span className="crayons-avatar crayons-avatar--l mr-3">
                      <img
                        className="crayons-avatar__image align-middle"
                        role="presentation"
                        src={membership.image}
                        alt={`${membership.name} profile`}
                      />
                    </span>
                    <span className="mr-2">{membership.name}</span>
                  </a>
                  {membership.role === 'member' &&
                    currentMembership.role === 'mod' ? (
                      <button
                        className="crayons-btn crayons-btn--icon-rounded crayons-btn--ghost"
                        type="button"
                        onClick={this.removeActiveMembership}
                        data-membership-id={membership.membership_id}
                        data-membership-status={membership.status}
                      >
                        x
                      </button>
                    ) : null}
                </div>
                ))
              : null}
          </div>
          {currentMembership.role === 'mod' ? (
            <div>
              <div className="p-4 grid gap-2 crayons-card mb-4">
                <h3 className="mb-2">Pending Invitations</h3>
                {pendingMemberships && pendingMemberships.length > 0
                  ? pendingMemberships.map((membership) => (
                    <div className="flex items-center">
                      <a href={`/${membership.username}`}>
                        <span className="crayons-avatar crayons-avatar--l mr-3">
                          <img
                            className="crayons-avatar__image align-middle"
                            role="presentation"
                            src={membership.image}
                            alt={`${membership.name} profile`}
                          />
                        </span>
                        <span className="mr-2">{membership.name}</span>
                      </a>
                      <button
                        className="crayons-btn crayons-btn--icon-rounded crayons-btn--ghost"
                        type="button"
                        onClick={this.removePendingMembership}
                        data-membership-id={membership.membership_id}
                        data-membership-status={membership.status}
                      >
                        x
                      </button>
                    </div>
                    ))
                  : null}
              </div>
              <div className="p-4 grid gap-2 crayons-card mb-4">
                <h3 className="mb-2">Joining Request</h3>
                {requestedMemberships && requestedMemberships.length > 0
                  ? requestedMemberships.map((membership) => (
                    <div className="flex items-center">
                      <a href={`/${membership.username}`}>
                        <span className="crayons-avatar crayons-avatar--l mr-3">
                          <img
                            className="crayons-avatar__image align-middle"
                            role="presentation"
                            src={membership.image}
                            alt={`${membership.name} profile`}
                          />
                        </span>
                        <span className="mr-2">{membership.name}</span>
                      </a>
                      <button
                        className="crayons-btn crayons-btn--icon-rounded crayons-btn--ghost"
                        type="button"
                        onClick={this.chatChannelAcceptMembership}
                        data-membership-id={membership.membership_id}
                      >
                        +
                      </button>
                      <button
                        className="crayons-btn crayons-btn--icon-rounded crayons-btn--ghost"
                        type="button"
                        onClick={this.removeRequestedMembership}
                        data-membership-id={membership.membership_id}
                        data-membership-status={membership.status}
                      >
                        x
                      </button>
                    </div>
                    ))
                  : null}
              </div>
              <div className="crayons-card p-4 grid gap-2 mb-4">
                <div className="crayons-field">
                  <label
                    className="crayons-field__label"
                    htmlFor="chat_channel_membership_Usernames to Invite"
                  >
                    Usernames to invite
                  </label>
                  <input
                    placeholder="Comma separated"
                    className="crayons-textfield"
                    type="text"
                    value={invitationUsernames}
                    name="chat_channel_membership[invitation_usernames]"
                    id="chat_channel_membership_invitation_usernames"
                    onChange={this.handleInvitationUsernames}
                  />
                </div>
                <div>
                  <button
                    className="crayons-btn"
                    type="submit"
                    onClick={this.handleChatChannelInvitations}
                  >
                    Submit
                  </button>
                </div>
              </div>
              <div className="crayons-card p-4 grid gap-2 mb-4">
                <h3>Channel Settings</h3>
                <div className="crayons-field">
                  <label
                    className="crayons-field__label"
                    htmlFor="chat_channel_description"
                  >
                    Description
                  </label>
                  <textarea
                    className="crayons-textfield"
                    name="description"
                    id="chat_channel_description"
                    value={channelDescription}
                    ref={this.textarea}
                    onChange={this.handleDescriptionChange}
                  />
                </div>
                <div className="crayons-field crayons-field--checkbox">
                  <input
                    type="checkbox"
                    id="c2"
                    className="crayons-checkbox"
                    checked={channelDiscoverable}
                    onChange={this.handleChannelDiscoverableStatus}
                  />
                  <label htmlFor="c2" className="crayons-field__label">
                    Channel Discoverable
                  </label>
                </div>
                <div>
                  <button
                    className="crayons-btn"
                    type="submit"
                    onClick={this.handleChannelDescriptionChanges}
                  >
                    Submit
                  </button>
                </div>
              </div>
            </div>
          ) : null}
          <div className="crayons-card p-4 grid gap-2 mb-4">
            <h3>Personal Settings</h3>
            <h4>Notifications</h4>
            <div className="crayons-field crayons-field--checkbox">
              <input
                type="checkbox"
                id="c3"
                className="crayons-checkbox"
                checked={showGlobalBadgeNotification}
                onChange={this.handlePersonChatChennelSetting}
              />
              <label htmlFor="c3" className="crayons-field__label">
                Receive Notifications for New Messages
              </label>
            </div>
            <div>
              <button
                className="crayons-btn"
                type="submit"
                onClick={this.updateCurrentMembershipNotificationSettings}
              >
                Submit
              </button>
            </div>
          </div>
          {currentMembership.role === 'member' ? (
            <div className="crayons-card p-4 grid gap-2 mb-4">
              <h3>Danger Zone</h3>
              <div>
                <button
                  className="crayons-btn crayons-btn--danger"
                  type="submit"
                  onClick={this.handleleaveChatChannelMembership}
                >
                  Leave Channel
                </button>
              </div>
            </div>
          ) : null}
          {currentMembership.role === 'mod' ? (
            <div className="crayons-card grid gap-2 p-4">
              <p>
                Questions about Connect Channel moderation? Contact
                <a
                  href="mailto:yo@dev.to"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="mx-2"
                >
                  yo@dev.to
                </a>
              </p>
            </div>
          ) : null}
        </div>
      </div>
    );
  }
}
