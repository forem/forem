import * as Type from './components/ChatTypes';

/**
 *
 *
 * @param {object} state
 * @param {object} action
 *
 *
 */
export function connectReducer(state, action) {
  const { type, payload } = action;

  switch (type) {
    case Type.CLOSE_DELETE_MODAL:
      return {
        ...state,
        showDeleteModal: payload.showDeleteModal,
        messageDeleteId: payload.messageDeleteId,
      };

    case Type.LOAD_ACTIVE_CHANNEL_MESSAGES:
      return {
        ...state,
        messages: {
          ...state.messages,
          [payload.chatChannelId]: payload.messages,
        },
      };
    case Type.SET_OPEN_CHANNEL_LEFT_USER:
      return {
        ...state,
        channelUsers: {
          [payload.activeChannelId]: payload.leftUser,
        },
      };
    case Type.SET_ALL_OPEN_CHANNEL_USER:
      return {
        ...state,
        channelUsers: {
          [payload.activeChannelId]: {
            all: { username: 'all', name: 'To notify everyone here' },
            ...payload.leftUser,
          },
        },
      };
    case Type.SUBSCRIBE_PUSHER_CHANNEL:
      return {
        ...state,
        subscribedPusherChannels: payload.subscriptions,
      };
    case Type.UNOPENED_CHANNEL_IDS:
      return {
        ...state,
        unopenedChannelIds: payload.unopenedChannelIds,
      };
    case Type.UPDATE_NEW_MESSAGE:
      return {
        ...state,
        ...payload.newShowAlert,
        chatChannels: payload.newChannelsObj,
        messages: {
          ...state.messages,
          [payload.receivedChatChannelId]: payload.newMessages,
        },
      };

    case Type.UPDATE_CHANNEL_LIST:
      return {
        ...state,
        chatChannels: payload.newChannelsObj,
      };

    case Type.REMOVE_MESSAGE:
      return {
        ...state,
        messages: {
          [payload.activeChannelId]: [
            ...state.messages[payload.activeChannelId].filter(
              (oldMessage) => oldMessage.id !== payload.message.id,
            ),
          ],
        },
      };

    case Type.UPDATE_MESSAFGE:
      return {
        ...state,
        messages: payload.messages,
      };

    case Type.REACT_USER_MESSAGE:
      return {
        ...state,
        messages: payload.messages,
      };

    case Type.CLEAR_CHANNEL:
      return {
        ...state,
        messages: {
          ...state.messages,
          [payload.chatChannelId]: [],
        },
      };
    case Type.CHANNEL_ERROR:
      return {
        ...state,
        subscribedPusherChannels: [],
      };

    case Type.OBSERVER_CALLBACK_SCROLLED:
      return {
        ...state,
        scrolled: false,
        showAlert: false,
      };

    case Type.OBSER_CALLBACK_NOT_SCROLLED:
      return {
        ...state,
        scrolled: true,
        rerenderIfUnchangedCheck: Math.random(),
      };

    case Type.UPDATE_UNOPENED_CHANNEL_IDS:
      return {
        ...state,
        unopenedChannelIds: payload.unopened_ids,
      };

    case Type.LOAD_UPDATE_CHANNEL:
      return {
        ...state,
        chatChannels: payload.chatChannels,
        scrolled: payload.scrolled,
        channelsLoaded: payload.channelsLoaded,
        channelPaginationNum: payload.channelPaginationNum,
        filterQuery: payload.filterQuery,
        activeChannel: payload.activeChannel,
      };

    case Type.CHANNEL_LOAD_STATUS: {
      return {
        ...state,
        channelsLoaded: payload.channelsLoaded,
      };
    }

    case Type.SWITCH_ACTIVE_CHANNEL: {
      return {
        ...state,
        activeChannel: payload.activeChannel,
        activeChannelId: payload.activeChannelId,
        scrolled: payload.scrolled,
        showAlert: payload.showAlert,
        allMessagesLoaded: payload.allMessagesLoaded,
        showMemberlist: payload.showMemberlist,
        unopenedChannelIds: payload.unopenedChannelIds,
      };
    }

    case Type.SET_ACTIVE_CONTENT_STATE: {
      return {
        ...state,
        activeContent: {
          ...state.activeContent,
          [payload.channelId]: payload.result,
        },
      };
    }

    case Type.FETCHING_PAGINATED_CHANNEL:
      return {
        ...state,
        fetchingPaginatedChannels: true,
      };

    case Type.LOAD_PAGINATED_CHANNELS:
      return {
        ...state,
        chatChannels: payload.chatChannels,
        fetchingPaginatedChannels: false,
        channelPaginationNum: payload.channelPaginationNum,
      };

    case Type.UPDATE_REQUEST_COUNT:
      return {
        ...state,
        userRequestCount: payload.userRequestCount,
      };
    case Type.SET_VIDEO_PATH:
      return {
        ...state,
        videoPath: payload.videoPath,
      };
    case Type.HANDLE_SCREEN:
      return {
        ...state,
        fullscreenContent: payload.fullscreenContent,
        expanded: payload.expanded,
      };
    case Type.UPDATE_FULL_SCREEN_CONSTENT:
      return {
        ...state,
        fullscreenContent: null,
      };
    case Type.UPDATE_CHAT_CHANNEL_REQUEST_COUNT:
      return {
        ...state,
        userRequestCount: payload.userRequestCount,
      };
    case Type.UPDATE_FILTER_QUERY:
      return {
        ...state,
        filterQuery: payload.query,
      };
    case Type.SHOW_SEARCH:
      return {
        ...state,
        searchShowing: payload.searchShowing,
      };
    case Type.LEFT_CHANNEL:
      return {
        ...state,
        chatChannels: {
          ...state.chatChannels.filter(
            (channel) => channel.id !== payload.leftChannelId,
          ),
        },
      };
    case Type.UPDATE_CHANNEL_FILTER:
      return {
        ...state,
        channelTypeFilter: payload.channelTypeFilter,
        fetchingPaginatedChannels: payload.fetchingPaginatedChannels,
      };
    case Type.TOGGEL_SCREEN:
      return {
        ...state,
        expanded: payload.expanded,
      };
    case Type.CURRENT_MESSAGE_LOCATION:
      return {
        ...state,
        currentMessageLocation: payload.currentMessageLocation,
      };
    case Type.ALL_MESSAGE_LOADED:
      return {
        ...state,
        allMessagesLoaded: payload.allMessagesLoaded,
      };
    case Type.ADD_MESSAGE:
      return {
        ...state,
        messages: {
          [payload.chatChannelId]: [
            ...payload.messages,
            ...state.messages[payload.chatChannelId],
          ],
        },
      };
    case Type.SHOW_MEMBER_LIST:
      return {
        ...state,
        showMemberlist: payload.showMemberlist,
      };
    case type.TRIGGER_MESSAGES_DELETE:
      return {
        ...state,
        messageDeleteId: payload.messageDeleteId,
        showDeleteModal: payload.showDeleteModal,
      };
    case Type.TRIGGER_EDIT_MESSAGE:
      return {
        ...state,
        startEditing: payload.startEditing,
        activeEditMessage: payload.activeEditMessage,
      };
    case Type.EXIT_VIDEO_CONTENT:
      return {
        ...state,
        videoPath: payload.videoPath,
        fullscreenContent: payload.fullscreenContent,
        expanded: payload.expanded,
      };
    case Type.UPDATE_MESSAGE_ON_SUCCESS:
      return {
        ...state,
        messages: payload.messages,
      };
    case Type.EDIT_MESSAGE_CLOSE:
      return {
        ...state,
        startEditing: payload.startEditing,
        markdownEdited: payload.markdownEdited,
        activeEditMessage: payload.activeEditMessage,
      };
    case Type.HANDLE_ALERT:
      return {
        ...state,
        scrolled: payload.scrolled,
        showAlert: payload.showAlert,
      };
    case Type.MARK_DOWN_EDITED:
      return {
        ...state,
        markdownEdited: payload.markdownEdited,
      };
    case Type.MEMBER_FILTER_QUERY:
      return {
        ...state,
        memberFilterQuery: payload.memberFilterQuery,
      };
    case Type.UPDATE_DELETE_MODAL_STATE:
      return {
        ...state,
        showDeleteModal: payload.showDeleteModal,
      };
    case Type.TRIGGER_DELETE_MESSAGE:
      return {
        ...state,
        messageDeleteId: payload.messageDeleteId,
        showDeleteModal: payload.showDeleteModal,
      };
    default:
      return state;
  }
}
