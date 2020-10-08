/*
  eslint-disable
  consistent-return, no-unused-vars, react/destructuring-assignment,
  react/no-access-state-in-setstate, react/button-has-type
*/

import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { useContext, useEffect } from 'preact/hooks';
import { setupPusher } from '../utilities/connect';
import debounceAction from '../utilities/debounceAction';
import { addSnackbarItem } from '../Snackbar';
import { processImageUpload } from '../article-form/actions';
import { ConnectStateProvider , store } from './components/ConnectStateProvider';
import { connectReducer } from './connectReducer';
import {
  conductModeration,
  getAllMessages,
  sendMessage,
  sendOpen,
  getChannels,
  getUnopenedChannelIds,
  getContent,
  deleteMessage,
  editMessage,
} from './actions/actions';
import {
  sendChannelRequest,
  rejectJoiningRequest,
  acceptJoiningRequest,
  getChannelRequestInfo,
} from './actions/requestActions';
import {
  hideMessages,
  scrollToBottom,
  setupObserver,
  getCurrentUser,
} from './util';
import Channels from './channels';
import Message from './message';
import ActionMessage from './actionMessage';
import ActiveChatChannel from './ActiveChatChannel';


const NARROW_WIDTH_LIMIT = 767;
const WIDE_WIDTH_LIMIT = 1600;

const ChatContent = ({}) => {
  const { state, dispatch } = useContext(store);

  useEffect(() => {
    setupChannels(state.chatChannels);

    const channelsForPusherSub = state.chatChannels.filter(
      channelTypeFilterFn('open'),
    );

    subscribeChannelsToPusher(
      channelsForPusherSub,
      (channel) => `open-channel--${state.appName}-${channel.chat_channel_id}`,
    );

    setupObserver(observerCallback);

    subscribePusher(
      `private-message-notifications--${state.appName}-${state.currentUserId}`,
    );

    if (state.activeChannelId) {
      handleOpenMessages(state.activeChannelId);
    }

    if (state.showChannelsList) {
      const filters =
      state.channelTypeFilter === 'all'
        ? {}
        : { filters: `channel_type:${state.channelTypeFilter}` };
    const searchParams = {
      query: '',
      retrievalID: state.activeChannelId,
      searchType: '',
      paginationNumber: state.channelPaginationNum,
    };
    if (state.activeChannelId !== null) {
      searchParams.searchType = 'discoverable';
    }
    getChannels(searchParams, filters, loadChannels);
    updateUnopenedChannelIds();
    }

    console.log(document.getElementById('messageform'));
    if (!state.isMobileDevice) {
      document.getElementById('messageform').focus();
    }

    if (document.getElementById('chatchannels__channelslist')) {
      document
        .getElementById('chatchannels__channelslist')
        .addEventListener('scroll', handleChannelScroll);
    }

    handleRequestCount();
  }, [state.rerenderIfUnchangedCheck]);

  const observerCallback = (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting && state.scrolled === true) {
        updateState('observerCallbaclScrolled', {})
      } else if (state.scrolled === false) {
        updateState('observerCallbackNotScrolled', {})
      }
    });
  };

  const updateUnopenedChannelIds = () => {
    getUnopenedChannelIds()
      .then(response => {
        updateState('updateUnopenedChannelIds', {unopened_ids: response.unopened_ids})
      });
  };

  const setupChannels = (channels) => {
    const { activeChannel } = state;
    channels.forEach((channel, index) => {
      if (index < 3) {
        setupChannel(channel.chat_channel_id, activeChannel);
      }
    });
  };

  const setupChannel = (channelId, activeChannel) => {
    const { messages, messageOffset } = state;
    if (
      !messages[channelId] ||
      messages[channelId].length === 0 ||
      messages[channelId][0].reception_method === 'pushed'
    ) {
      receiveAllMessages(channelId, messageOffset);
    }
    if (
      activeChannel &&
      activeChannel.channel_type !== 'direct' &&
      activeChannel.chat_channel_id === channelId
    ) {
      setOpenChannelUsers(channelId);
      if (activeChannel.channel_type === 'open')
        subscribePusher(`open-channel--${state.appName}-${channelId}`);
    }
    subscribePusher(`private-channel--${state.appName}-${channelId}`);
  };

  const setOpenChannelUsers = (channelId) => {
    getContent(`/chat_channels/${channelId}/channel_info`)
    .then(response => {
      const { activeChannelId, activeChannel } = state;
      Object.filter = (obj, predicate) =>
      Object.fromEntries(Object.entries(obj).filter(predicate));
      const leftUser = Object.filter(
        response.channel_users,
        ([username]) => username !== window.currentUser.username,
      );
      if (activeChannel && activeChannel.channel_type === 'open') {
        updateState('setOpenChannelLeftUser', {
          activeChannelId,
          leftUser
        })
      } else {
        updateState('setAllOpenChannelUser', {
          activeChannelId,
          leftUser
        })
      }
    })
  };

  const handleRequestCount = () => {
    getChannelRequestInfo().then((response) => {
      const { result } = response;
      const { user_joining_requests, channel_joining_memberships } = result;
      let totalRequest =
        user_joining_requests?.length + channel_joining_memberships?.length;
      updateState('udpateRequestCount', {userRequestCount: totalRequest})
    });
  };

  const channelTypeFilterFn = (type) => (channel) => {
    return channel.channel_type === type;
  };

  const subscribeChannelsToPusher = (channels, channelNameFn) => {
    channels.forEach((channel) => {
      subscribePusher(channelNameFn(channel));
    });
  };

  const subscribePusher = (channelName) => {
    const { subscribedPusherChannels, pusherKey } = state;
    if (!subscribedPusherChannels.includes(channelName)) {
      setupPusher(pusherKey, {
        channelId: channelName,
        messageCreated: receiveNewMessage,
        messageDeleted: removeMessage,
        messageEdited: updateMessage,
        channelCleared: clearChannel,
        redactUserMessages,
        channelError,
        mentioned,
        messageOpened,
      });
      const subscriptions = subscribedPusherChannels;
      subscriptions.push(channelName);
      updateState('subscribePusherChannel', {subscriptions})
    }
  };

  const receiveNewMessage = (message) => {
    const {
      messages,
      activeChannelId,
      scrolled,
      chatChannels,
      unopenedChannelIds,
    } = state;

    const receivedChatChannelId = message.chat_channel_id;
    const messageList = document.getElementById('messagelist');
    let newMessages = [];

    const nearBottom =
      messageList.scrollTop + messageList.offsetHeight + 400 >
      messageList.scrollHeight;

    if (nearBottom) {
      scrollToBottom();
    }
    // Remove reduntant messages
    if (
      message.temp_id &&
      messages[receivedChatChannelId] &&
      messages[receivedChatChannelId].findIndex(
        (oldmessage) => oldmessage.temp_id === message.temp_id,
      ) > -1
    ) {
      return;
    }

    if (messages[receivedChatChannelId]) {
      newMessages = messages[receivedChatChannelId].slice();
      newMessages.push(message);
      if (newMessages.length > 150) {
        newMessages.shift();
      }
    }

    //Show alert if message received and you have scrolled up
    const newShowAlert =
      activeChannelId === receivedChatChannelId
        ? { showAlert: !nearBottom }
        : {};

    let newMessageChannelIndex = 0;
    let newMessageChannel = null;
    const newChannelsObj = chatChannels.map((channel, index) => {
      if (receivedChatChannelId === channel.chat_channel_id) {
        newMessageChannelIndex = index;
        newMessageChannel = channel;
        return { ...channel, channel_last_message_at: new Date() };
      }
      return channel;
    });

    if (newMessageChannelIndex > 0) {
      newChannelsObj.splice(newMessageChannelIndex, 1);
      newChannelsObj.unshift(newMessageChannel);
    }

    // Mark messages read
    if (receivedChatChannelId === activeChannelId) {
      handleOpenMessages(receivedChatChannelId);
    } else {
      const newUnopenedChannels = unopenedChannelIds;
      if (!unopenedChannelIds.includes(receivedChatChannelId)) {
        newUnopenedChannels.push(receivedChatChannelId);
      }

      updateState('unopenedChannelIds', {unopenedChannelIds})
    }

    // Updating the messages
    updateState('updateNewMessage', {newShowAlert, newChannelsObj, receivedChatChannelId, newMessages})
  };

  const handleOpenMessages = (receivedChatChannelId) => {
    sendOpen(receivedChatChannelId)
      .then(response => {
        const newChannelsObj = state.chatChannels.map((channel) => {
          if (parseInt(response.channel, 10) === channel.chat_channel_id) {
            return { ...channel, last_opened_at: new Date() };
          }
          return channel
        });
        updateState('updateChannelList', {newChannelsObj})
      })

  };

  const removeMessage = (message) => {
    const { activeChannelId } = state;
    updateState('removeMessage', {activeChannelId, message})
  };

  const updateMessage = (message) => {
    const { activeChannelId, messages } = state;
    if (message.chat_channel_id === activeChannelId) {
        const newMessages = messages;
        const foundIndex = messages[activeChannelId].findIndex(
          (oldMessage) => oldMessage.id === message.id,
        );
        newMessages[activeChannelId][foundIndex] = message;
        updateState('updateMessage', {
          newMessages,
        });
    }
  };

  const redactUserMessages = (res) => {
    const { messages } = state;
    const newMessages = hideMessages(messages, res.userId);
    updateState('reactUserMessage', {newMessages})
  };

  const clearChannel = (res) => {
    updateState('clearChannel', {chatChannelId: res.chat_channel_id})
  };

  const channelError = (_error) => {
    updateState('channelError', {})
  };

  const mentioned = () => {};

  const messageOpened = () => {};

  const loadChannels = (channels, query) => {
    console.log(channels, query)
    const { activeChannelId, appName } = state;
    const activeChannel =
      state.activeChannel ||
      channels.filter(
        (channel) => channel.chat_channel_id === activeChannelId,
      )[0];
    if (activeChannelId && query.length === 0) {
      updateState('loadUpdatedChannel', {
        chatChannels: channels,
        scrolled: false,
        channelsLoaded: true,
        channelPaginationNum: 0,
        filterQuery: '',
        activeChannel: activeChannel || filterForActiveChannel(channels, activeChannelId),
      })
      setupChannel(activeChannelId, activeChannel);
    } else if (activeChannelId) {
      updateState('loadUpdatedChannel', {
        chatChannels: channels,
        scrolled: false,
        channelsLoaded: true,
        channelPaginationNum: 0,
        filterQuery: query,
        activeChannel: activeChannel || filterForActiveChannel(channels, activeChannelId),
      });
      setupChannel(activeChannelId, activeChannel);
    } else if (channels.length > 0) {
      updateState('loadUpdatedChannel', {
        chatChannels: channels,
        scrolled: false,
        channelsLoaded: true,
        channelPaginationNum: 0,
        filterQuery: query || '',
        activeChannel,
      });

      triggerSwitchChannel(
        channels[0].chat_channel_id,
        channels[0].channel_modified_slug,
        channels,
      );
      setupChannels(channels);
    } else {
      updateState('channelLoadStatus', {channelsLoaded: true})
    }
    subscribeChannelsToPusher(
      channels.filter(channelTypeFilterFn('open')),
      (channel) => `open-channel--${appName}-${channel.chat_channel_id}`,
    );
    subscribeChannelsToPusher(
      channels.filter(channelTypeFilterFn('invite_only')),
      (channel) => `private-channel--${appName}-${channel.chat_channel_id}`,
    );
    const chatChannelsList = document.getElementById(
      'chatchannels__channelslist',
    );

    if (chatChannelsList) {
      chatChannelsList.scrollTop = 0;
    }
  };

  const handleChannelScroll = (e) => {
    const {
      fetchingPaginatedChannels,
      chatChannels,
      channelTypeFilter,
      filterQuery,
      activeChannelId,
      channelPaginationNum,
    } = state;

    if (fetchingPaginatedChannels || chatChannels.length < 30) {
      return;
    }
    const { target } = e;
    if (target.scrollTop + target.offsetHeight + 1800 > target.scrollHeight) {
      updateState('fetchingPaginatedChannels', {})
      const filters =
        channelTypeFilter === 'all'
          ? {}
          : { filters: `channel_type:${channelTypeFilter}` };
      const searchParams = {
        query: filterQuery,
        retrievalID: activeChannelId,
        searchType: '',
        paginationNumber: channelPaginationNum,
      };
      getChannels(searchParams, filters, loadPaginatedChannels);
    }
  };

  const loadPaginatedChannels = (channels) => {
    const currentChannels = state.chatChannels;
    const currentChannelIds = currentChannels.map((channel) => channel.id);
    const newChannels = currentChannels;
    channels.forEach((channel) => {
      if (!currentChannelIds.includes(channel.id)) {
        newChannels.push(channel);
      }
    });
    if (
      currentChannels.length === newChannels.length &&
      state.channelPaginationNum > 3
    ) {
      return;
    }
    updateState('loadPaginatedChannels', {
      chatChannels: newChannels,
      fetchingPaginatedChannels: false,
      channelPaginationNum: state.channelPaginationNum + 1,
    })
  };

  const triggerSwitchChannel = (id, slug, channels) => {
    const {
      chatChannels,
      isMobileDevice,
      unopenedChannelIds,
      activeChannelId,
      currentUserId,
    } = state;
    const channelList = channels || chatChannels;
    const newUnopenedChannelIds = unopenedChannelIds;
    const index = newUnopenedChannelIds.indexOf(id);
    if (index > -1) {
      newUnopenedChannelIds.splice(index, 1);
    }

    let updatedActiveChannel = filterForActiveChannel(
      channelList,
      id,
      currentUserId,
    );

    updateState('switchActiveChannel', {
      activeChannel: updatedActiveChannel,
      activeChannelId: parseInt(id, 10),
      scrolled: false,
      showAlert: false,
      allMessagesLoaded: false,
      showMemberlist: false,
      unopenedChannelIds: unopenedChannelIds.filter(
        (unopenedId) => unopenedId !== id,
      )
    });

    setupChannel(id, updatedActiveChannel);
    const params = new URLSearchParams(window.location.search);

    if (params.get('ref') === 'group_invite') {
      setActiveContentState(activeChannelId, {
        type_of: 'loading-post',
      });
      setActiveContent({
        path: '/chat_channel_memberships',
        type_of: 'article',
      });
    }
    window.history.replaceState(null, null, `/connect/${slug}`);
    if (!isMobileDevice) {
      document.getElementById('messageform').focus();
    }
    if (window.ga && ga.create) {
      ga('send', 'pageview', window.location.pathname + window.location.search);
    }
    handleOpenMessages(id);
  };

  const hideChannelList = () => {
    const chatContainer = document.querySelector('.chat__activechat');
    chatContainer.classList.remove('chat__activechat--hidden');
  };

  const handleRequestRejection = (e) => {
    rejectJoiningRequest(
      e.target.dataset.channelId,
      e.target.dataset.membershipId
    );
  };

  const handleRequestApproval = (e) => {
    acceptJoiningRequest(
      e.target.dataset.channelId,
      e.target.dataset.membershipId
    );
  };

  const handleSwitchChannel = (e) => {
    e.preventDefault();
    let { target } = e;
    hideChannelList();
    if (!target.dataset.channelId) {
      target = target.parentElement;
    }
    triggerSwitchChannel(
      parseInt(target.dataset.channelId, 10),
      target.dataset.channelSlug,
    );
  };

  const handleJoiningRequest = (e) => {
    sendChannelRequest(
      e.target.dataset.channelId,
      handleJoiningRequestSuccess,
      handleFailure,
    );
  };

  const handleFailure = (err) => {
    // eslint-disable-next-line no-console
    console.error(err);
    addSnackbarItem({ message: err, addCloseButton: true });
  };

  const handleJoiningRequestSuccess = () => {
    const { activeChannelId } = state;
    setActiveContentState(activeChannelId, null);
    updateState('updateFullScreenContent', {})
    toggleSearchShowing();
  };

  const handleUpdateRequestCount = (isAccepted = false, acceptedInfo) => {
    if (isAccepted) {
      const searchParams = {
        query: '',
        retrievalID: null,
        searchType: '',
        paginationNumber: 0,
      };
      getChannels(searchParams, 'all', loadChannels);
      triggerSwitchChannel(
        parseInt(acceptedInfo.channelId, 10),
        acceptedInfo.channelSlug,
        state.chatChannels,
      );
    }

    updateState('UpdateChatChannelRequestCount', {userRequestCount: state.userRequestCount - 1})
  };

  const toggleSearchShowing = () => {
    if (!state.searchShowing) {
      setTimeout(() => {
        document.getElementById('chatchannelsearchbar').focus();
      }, 100);
    } else {
      const searchParams = {
        query: '',
        retrievalID: null,
        searchType: '',
        paginationNumber: 0,
      };
      getChannels(searchParams, 'all', loadChannels);
      updateState('updateFilterQuery', {query: null})
    }
    updateState('showSearch', {searchShowing: !state.searchShowing})
  };

  const triggerActiveContent = (e) => {
    console.log(e, 'Iamtriggered');
    if (
      // Trying to open in new tab
      e.ctrlKey ||
      e.shiftKey ||
      e.metaKey || // apple
      (e.button && e.button === 1) // middle click, >IE9 + everyone else
    ) {
      return false;
    }
    const { target } = e;
    const content =
      target.dataset.content || target.parentElement.dataset.content;
      console.log(target.dataset.content);
    if (content) {
      e.preventDefault();
      e.stopPropagation();
      hideChannelList();

      const { activeChannelId, activeChannel } = state;

      if (content.startsWith('chat_channels/')) {
        setActiveContentState(activeChannelId, {
          type_of: 'loading-user',
        });
        getContent(`/${content}/channel_info`)
          .then(response => {
            setActiveContent(response)
          });
        
      } else if (content === 'sidecar-channel-request') {
        setActiveContent({
          data: {
            user: getCurrentUser(),
            channel: {
              id: target.dataset.channelId,
              name: target.dataset.channelName,
              status: target.dataset.channelStatus,
            },
          },
          handleJoiningRequest,
          type_of: 'channel-request',
        });
      } else if (content === 'sidecar-joining-request-manager') {
        setActiveContent({
          data: {},
          type_of: 'channel-request-manager',
          updateRequestCount: handleUpdateRequestCount,
        });
      } else if (content === 'sidecar_all') {
        setActiveContentState(activeChannelId, {
          type_of: 'loading-post',
        });
        setActiveContent({
          path: `/chat_channel_memberships/${activeChannel.id}/edit`,
          type_of: 'article',
        });
      } else if (content.startsWith('sidecar-content-plus-video')) {
        setActiveContentState(activeChannelId, {
          type_of: 'loading-post',
        });
        setActiveContent({
          path: target.href || target.parentElement.href,
          type_of: 'article',
        });
        updateState('setVideoPath', {videoPath: `/video_chats/${activeChannelId}`})

      } else if (content.startsWith('sidecar-video')) {
        updateState('setVideoPath', {videoPath:  target.href || target.parentElement.href})
      } else if (
        content.startsWith('sidecar') ||
        content.startsWith('article')
      ) {
        // article is legacy which can be removed shortly
        setActiveContentState(activeChannelId, {
          type_of: 'loading-post',
        });
        setActiveContent({
          path: target.href || target.parentElement.href,
          type_of: 'article',
        });
      } else if (target.dataset.content === 'exit') {
        setActiveContentState(activeChannelId, null);
        updateState('handleScreen', {
          fullscreenContent: null,
          expanded: window.innerWidth > NARROW_WIDTH_LIMIT,
        });

      } else if (target.dataset.content === 'fullscreen') {
        const mode =
          state.fullscreenContent === 'sidecar' ? null : 'sidecar';
          updateState('handleScreen', {
            fullscreenContent: mode,
            expanded: mode === null || window.innerWidth > WIDE_WIDTH_LIMIT,
          });
      } else if (target.dataset.content === 'chat_channel_setting') {
        setActiveContent({
          data: {},
          type_of: 'chat-channel-setting',
          activeMembershipId: activeChannel.id,
          handleLeavingChannel,
        });
      }
    }
    return false;
  };

  const handleLeavingChannel = (leftChannelId) => {
    const { chatChannels } = state;
    triggerSwitchChannel(
      chatChannels[1].chat_channel_id,
      chatChannels[1].channel_modified_slug,
      chatChannels,
    );
    updateState('leftChannel', {leftChannelId})
    setActiveContentState(chatChannels[1].chat_channel_id, null);
  };

  const filterForActiveChannel = (channels, id, currentUserId) =>
  channels.filter(
    (channel) =>
      channel.chat_channel_id === parseInt(id, 10) &&
      channel.viewable_by === parseInt(currentUserId, 10),
  )[0];

  const setActiveContentState = (channelId, result) => {
    updateState('setActicveContentState', {channelId, result})
  };


  const setActiveContent = (response) => {
    const { activeChannelId } = state;
    setActiveContentState(activeChannelId, response);
    setTimeout(() => {
      document.getElementById('chat_activecontent').scrollTop = 0;
      document.getElementById('chat').scrollLeft = 1000;
    }, 3);
    setTimeout(() => {
      document.getElementById('chat_activecontent').scrollTop = 0;
      document.getElementById('chat').scrollLeft = 1000;
    }, 10);
  };

  const updateState = (type, data) => {
    dispatch({
      type,
      payload: data
    });
  };

  const receiveAllMessages = (chatChannelId, offset) => {
    getAllMessages(chatChannelId, offset)
    .then((res) => {
      updateState('loadActiveChannelMessages', {
        chatChannelId: res.chatChannelId,
        messages: res.messages
      })
    })
  };

  const toggleExpand = () => {
    updateState('toggleScreen', { expanded: !state.expanded})
  };

  const triggerChannelTypeFilter = (e) => {
    const { filterQuery } = state;
    const type = e.target.dataset.channelType;
    updateState('updateChannelFilter', {channelTypeFilter: type, fetchingPaginatedChannels: false})
    const filters = type === 'all' ? {} : { filters: `channel_type:${type}` };
    const searchParams = {
      query: filterQuery,
      retrievalID: null,
      searchType: '',
      paginationNumber: 0,
    };
    if (filterQuery && type !== 'direct') {
      searchParams.searchType = 'discoverable';
      getChannels(searchParams, filters, loadChannels);
    } else {
      getChannels(searchParams, filters, loadChannels);
    }
  };

  const triggerChannelFilter = (e) => {
    const { channelTypeFilter } = state;
    const filters =
      channelTypeFilter === 'all'
        ? {}
        : { filters: `channel_type:${channelTypeFilter}` };
    const searchParams = {
      query: e.target.value,
      retrievalID: null,
      searchType: '',
      paginationNumber: 0,
    };
    if (e.target.value) {
      searchParams.searchType = 'discoverable';
      getChannels(searchParams, filters, loadChannels);
    } else {
      getChannels(searchParams, filters, loadChannels);
    }
  };

  const renderChannelFilterButton = (type, name, active) => (
    <button
      data-channel-type={type}
      onClick={triggerChannelTypeFilter}
      className={`chat__channeltypefilterbutton crayons-indicator crayons-indicator--${
        type === active ? 'accent' : ''
      }`}
      type="button"
    >
      {name}
    </button>
  );

  const renderChatChannels = () => {
    if (state.showChannelsList) {
      const { notificationsPermission } = state;
      const notificationsButton = '';
      let notificationsState = '';
      let invitesButton = '';
      let joiningRequestButton = '';
      if (notificationsPermission === 'granted') {
        notificationsState = (
          <div className="chat_chatconfig chat_chatconfig--on">
            Notifications On
          </div>
        );
      } else if (notificationsPermission === 'denied') {
        notificationsState = (
          <div className="chat_chatconfig chat_chatconfig--off">
            Notifications Off
          </div>
        );
      }

      return (
        <div className="chat__channels">
          {notificationsButton}
          {state.searchShowing ? (
            <input
              placeholder="Search Channels"
              // onKeyUp={this.debouncedChannelFilter}
              id="chatchannelsearchbar"
              className="crayons-textfield"
              aria-label="Search Channels"
            />
          ) : (
            ''
          )}
          {invitesButton}
          {joiningRequestButton}
          <div className="chat__channeltypefilter">
            <button
              className="chat__channelssearchtoggle"
              onClick={toggleSearchShowing}
              aria-label="Toggle channel search"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 24 24"
                width="17"
                height="17"
              >
                <path fill="none" d="M0 0h24v24H0z" />
                <path d="M18.031 16.617l4.283 4.282-1.415 1.415-4.282-4.283A8.96 8.96 0 0 1 11 20c-4.968 0-9-4.032-9-9s4.032-9 9-9 9 4.032 9 9a8.96 8.96 0 0 1-1.969 5.617zm-2.006-.742A6.977 6.977 0 0 0 18 11c0-3.868-3.133-7-7-7-3.868 0-7 3.132-7 7 0 3.867 3.132 7 7 7a6.977 6.977 0 0 0 4.875-1.975l.15-.15z" />
              </svg>
            </button>
            {renderChannelFilterButton(
              'all',
              'all',
              state.channelTypeFilter,
            )}
            {renderChannelFilterButton(
              'direct',
              'direct',
              state.channelTypeFilter,
            )}
            {renderChannelFilterButton(
              'invite_only',
              'group',
              state.channelTypeFilter,
            )}
            <button
              className="chat__channelssearchtoggle "
              aria-label="Toggle request manager"
              onClick={triggerActiveContent}
              data-content="sidecar-joining-request-manager"
            >
              <span
                onClick={triggerActiveContent}
                data-content="sidecar-joining-request-manager"
                role="button"
                aria-hidden="true"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 477.869 477.869"
                  width="18"
                  height="18"
                >
                  <path d="M387.415 233.496c48.976-44.03 52.987-119.424 8.958-168.4C355.99 20.177 288.4 12.546 239.02 47.332c-53.83-38-128.264-25.15-166.254 28.68-34.86 49.393-27.26 117.054 17.69 157.483C34.606 262.935-.25 320.976.002 384.108v51.2a17.07 17.07 0 0 0 17.067 17.067h443.733a17.07 17.07 0 0 0 17.067-17.067v-51.2c.252-63.132-34.605-121.173-90.454-150.612zM307.2 59.842c47.062-.052 85.256 38.057 85.31 85.12.037 33.564-19.63 64.023-50.237 77.8-1.314.597-2.628 1.143-3.96 1.707a83.66 83.66 0 0 1-12.988 4.045c-.853.188-1.707.3-2.577.46-4.952.95-9.977 1.457-15.02 1.52-2.27 0-4.557-.17-6.827-.375-.853 0-1.707 0-2.56-.17a86.22 86.22 0 0 1-27.904-8.226c-.324-.154-.7-.137-1.024-.273-1.707-.82-3.413-1.536-4.932-2.458.137-.17.222-.358.358-.53a119.72 119.72 0 0 0 18.278-33.297l.53-1.434a120.38 120.38 0 0 0 4.523-17.562c.154-.87.273-1.707.4-2.645.987-6.067 1.506-12.2 1.553-18.347a120.04 120.04 0 0 0-1.553-18.313l-.4-2.645c-1.064-5.96-2.576-11.83-4.523-17.562l-.53-1.434c-4.282-12-10.453-23.24-18.278-33.297-.137-.17-.222-.358-.358-.53C277.45 63.83 292.2 59.843 307.2 59.842zM85.335 145.176c-.12-47.006 37.886-85.2 84.892-85.33a85.11 85.11 0 0 1 59.134 23.686l2.918 2.9a87.75 87.75 0 0 1 8.09 9.813c.75 1.058 1.434 2.185 2.133 3.277a83.95 83.95 0 0 1 6.263 11.52c.427.973.75 1.963 1.126 2.935a83.42 83.42 0 0 1 4.233 13.653c.12.512.154 1.024.256 1.553a80.34 80.34 0 0 1 0 32.119c-.102.53-.137 1.04-.256 1.553a83.23 83.23 0 0 1-4.233 13.653c-.375.973-.7 1.963-1.126 2.935a84.25 84.25 0 0 1-6.263 11.503c-.7 1.092-1.382 2.22-2.133 3.277a87.55 87.55 0 0 1-8.09 9.813 117.37 117.37 0 0 1-2.918 2.901c-6.9 6.585-14.877 11.962-23.57 15.906a49.35 49.35 0 0 1-4.198 1.707 85.84 85.84 0 0 1-12.663 3.925c-1.075.24-2.185.375-3.277.563a84.67 84.67 0 0 1-14.046 1.417h-1.877c-4.713-.08-9.412-.554-14.046-1.417-1.092-.188-2.202-.324-3.277-.563a85.8 85.8 0 0 1-12.663-3.925l-4.198-1.707c-30.534-13.786-50.173-44.166-50.212-77.667zM307.2 418.242H34.135V384.11c-.25-57.833 36.188-109.468 90.76-128.614 29.296 12.197 62.25 12.197 91.546 0a137.14 137.14 0 0 1 16.623 7.356c3.55 1.826 6.827 3.908 10.24 6.007 2.22 1.382 4.47 2.73 6.605 4.25 3.294 2.338 6.4 4.88 9.455 7.492l5.75 5.12c2.816 2.662 5.46 5.478 8.004 8.363 1.826 2.082 3.6 4.198 5.29 6.383 2.236 2.867 4.37 5.803 6.35 8.823 1.707 2.56 3.226 5.222 4.727 7.885 1.707 2.935 3.277 5.87 4.7 8.926s2.697 6.4 3.925 9.66c1.075 2.833 2.22 5.65 3.106 8.533 1.195 3.96 2.03 8.055 2.867 12.15.512 2.423 1.178 4.796 1.553 7.253 1.01 6.757 1.53 13.58 1.553 20.412v34.133zm136.534 0h-102.4V384.11c0-5.342-.307-10.633-.785-15.872-.137-1.536-.375-3.055-.546-4.59-.46-3.772-1-7.51-1.707-11.213l-.973-4.762c-.82-3.8-1.77-7.566-2.85-11.298l-1.058-3.686c-4.78-15.277-11.704-29.797-20.565-43.127l-.666-.973a168.96 168.96 0 0 0-9.404-12.646l-.12-.154c-3.413-4.232-7.117-8.346-11.008-12.237h.7a120.8 120.8 0 0 0 14.524 1.024h.94c4.496-.04 8.985-.33 13.45-.87 1.4-.17 2.782-.427 4.18-.65a117.43 117.43 0 0 0 10.752-2.167l3.055-.785a116.21 116.21 0 0 0 13.653-4.642c54.612 19.127 91.083 70.785 90.83 128.65v34.132z" />
                </svg>
                {state.userRequestCount > 0 ? (
                  <span className="crayons-indicator crayons-indicator--accent crayons-indicator--bullet requests-badge">
                    {state.userRequestCount}
                  </span>
                ) : null}
              </span>
            </button>
          </div>
          <Channels
            activeChannelId={state.activeChannelId}
            chatChannels={state.chatChannels}
            unopenedChannelIds={state.unopenedChannelIds}
            handleSwitchChannel={handleSwitchChannel}
            channelsLoaded={state.channelsLoaded}
            filterQuery={state.filterQuery}
            expanded={state.expanded}
            aria-expanded={state.expanded}
            currentUserId={state.currentUserId}
            triggerActiveContent={triggerActiveContent}
          />
          {notificationsState}
        </div>
      );
    }
    return '';
  };

  const navigateToChannelsList = () => {
    const chatContainer = document.querySelector('.chat__activechat');
    console.log(chatContainer);
    chatContainer.classList.add('chat__activechat--hidden');
  };

  const renderChannelBackNav = () => {
    return (
      <button
        className="crayons-btn crayons-btn--icon-rounded crayons-btn--ghost active-channel__back-btn"
        onClick={navigateToChannelsList}
        onKeyUp={(e) => {
          if (e.keyCode === 13) navigateToChannelsList(e);
        }}
        tabIndex="0"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          width="24"
          height="24"
          className="crayons-icon"
        >
          <path d="M10.828 12l4.95 4.95-1.414 1.414L8 12l6.364-6.364 1.414 1.414z" />
        </svg>
      </button>
    );
  };

  const renderChannelHeaderInner = () => {
    const { activeChannel } = state;
    if (activeChannel.channel_type === 'direct') {
      return (
        <a
          href={`/${activeChannel.channel_username}`}
          className="active-channel__title"
          onClick={triggerActiveContent}
          data-content="sidecar-user"
        >
          {activeChannel.channel_modified_slug}
        </a>
      );
    }
    return (
      <a
        href="#/"
        onClick={triggerActiveContent}
        data-content="chat_channel_setting"
      >
        {activeChannel.channel_name}
      </a>
    );
  };

  const renderChannelConfigImage = () => {
    const { activeContent, activeChannel, activeChannelId } = state;
    if (
      activeContent[activeChannelId] &&
      activeContent[activeChannelId].type_of
    ) {
      return '';
    }

    const path =
      activeChannel.channel_type === 'direct'
        ? `/${activeChannel.channel_username}`
        : `#`;

    const dataContent =
      activeChannel.channel_type === 'direct'
        ? 'sidecar-user'
        : `chat_channel_setting`;

    const contentLink =
      activeChannel.channel_type === 'direct'
        ? `/${activeChannel.channel_username}`
        : '#/';

    return (
      <a
        className="crayons-btn crayons-btn--icon-rounded crayons-btn--ghost"
        onClick={triggerActiveContent}
        onKeyUp={(e) => {
          if (e.keyCode === 13) triggerActiveContent(e);
        }}
        tabIndex="0"
        href={contentLink}
        data-content={dataContent}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 24 24"
          width="24"
          height="24"
          className="crayons-icon"
          data-content={dataContent}
        >
          <path
            data-content={dataContent}
            d="M12 22C6.477 22 2 17.523 2 12S6.477 2 12 2s10 4.477 10 10-4.477 10-10 10zm0-2a8 8 0 1 0 0-16 8 8 0 0 0 0 16zM11 7h2v2h-2V7zm0 4h2v6h-2v-6z"
          />
        </svg>
      </a>
    );
  };

  let channelHeader = <div className="active-channel__header">&nbsp;</div>;

  if (state.activeChannel) {
    channelHeader = (
      <div className="active-channel__header">
        {renderChannelBackNav()}
        {renderChannelHeaderInner()}
        {renderChannelConfigImage()}
      </div>
    );
  }

  let fullscreenMode = '';
  if (state.fullscreenContent === 'sidecar') {
    fullscreenMode = 'chat--content-visible-full';
  } else if (state.fullscreenContent === 'video') {
    fullscreenMode = 'chat--video-visible-full';
  }

  return (
    <div
    data-testid="chat"
    className={`chat chat--expanded
    chat--${
      state.videoPath ? 'video-visible' : 'video-not-visible'
    } chat--${
      state.activeContent[state.activeChannelId]
        ? 'content-visible'
        : 'content-not-visible'
    } ${fullscreenMode}`}
    data-no-instant
    aria-expanded={state.expanded}
  >
    {renderChatChannels()}
      <div data-testid="active-chat" className="chat__activechat">
        <ActiveChatChannel
          channelHeader={channelHeader}
          setActiveContentState={setActiveContentState}
          setActiveContent={setActiveContent}
          handleFailure={handleFailure}
          triggerActiveContent={triggerActiveContent}
        />
      </div>
    </div>
  );
}

export default ChatContent;
