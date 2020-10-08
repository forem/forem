export function connectReducer(state, action) {
  const { type, payload = {} } = action;

  switch (type) {
    case 'closeDeleteModal':
      return {
        ...state,
        showDeleteModal: payload.showDeleteModal,
        messageDeleteId: payload.messageDeleteId,
      };
    case 'loadActiveChannelMessages':
      return {
        ...state,
        messages: { ...state.messages, [payload.chatChannelId]: payload.messages}
      }
    case 'setOpenChannelLeftUser': 
      return {
        ...state,
        channelUsers: {
          [payload.activeChannelId]: payload.leftUser
        }
      }
    case 'setAllOpenChannelUser':
      return {
        ...state,
        channelUsers: {
          [payload.activeChannelId]: {
            all: { username: 'all', name: 'To notify everyone here' },
            ...payload.leftUser
          }
        }
      }
    case 'subscribePusherChannel':
      return {
        ...state,
        subscribedPusherChannels: payload.subscriptions
      }
    case 'unopenedChannelIds':
      return {
        ...state,
        unopenedChannelIds: payload.unopenedChannelIds
      }
    case 'updateNewMessage':
      return {
        ...state,
        ...payload.newShowAlert,
        chatChannels: payload.newChannelsObj,
        messages: {
          ...state.messages,
          [payload.receivedChatChannelId]: payload.newMessages
        }
      }
    
    case 'updateChannelList': 
      return {
        ...state,
        chatChannels: payload.newChannelsObj
      }

    case 'removeMessage': 
      return {
        ...state,
        messages: {
          [payload.activeChannelId]: [
            ...state.messages[payload.activeChannelId].filter(
              (oldMessage) => oldMessage.id !== payload.message.id
            )
          ]
        }
      }

    case 'updateMessage':
      return {
        ...state,
        messages: payload.messages,
      }

    case 'reactUserMessage':
      return {
        ...state,
        messages: payload.messages
      }
    
    case 'clearChannel': 
      return {
        ...state,
        messages: {
          ...state.messages, [payload.chatChannelId]: []
        }
      }
    case 'channelError':
      return {
        ...state,
        subscribedPusherChannels: []
      }
    
    case 'observerCallbaclScrolled': 
     return {
       ...state,
       scrolled: false,
       showAlert: false,
     }

    case 'observerCallbackNotScrolled': 
     return {
       ...state, 
       scrolled: true,
       rerenderIfUnchangedCheck: Math.random(),
     }

    case 'updateUnopenedChannelIds': 
     return {
       ...state,
       unopenedChannelIds: payload.unopened_ids
     }

     case 'loadUpdatedChannel':
       return {
         ...state,
         chatChannels: payload.chatChannels,
         scrolled: payload.scrolled,
         channelsLoaded: payload.channelsLoaded,
         channelPaginationNum: payload.channelPaginationNum,
         filterQuery: payload.filterQuery,
         activeChannel: payload.activeChannel,
       }
    
       case 'channelLoadStatus': {
         return {
           ...state,
           channelsLoaded: payload.channelsLoaded
         }
       }

       case 'switchActiveChannel': {
         return {
           ...state,
           activeChannel: payload.activeChannel,
           activeChannelId: payload.activeChannelId,
           scrolled: payload.scrolled,
           showAlert: payload.showAlert,
           allMessagesLoaded: payload.allMessagesLoaded,
           showMemberlist: payload.showMemberlist,
           unopenedChannelIds: payload.unopenedChannelIds,
         }
       }

       case 'setActiveContentState': {
         return {
           ...state,
           activeContent: {
             ...state.activeContent,
             [payload.channelId]: payload.result
           }
         }
       }

       case 'fetchingPaginatedChannels': 
       return {
         ...state,
         fetchingPaginatedChannels: true,
       }

       case 'loadPaginatedChannels': 
        return {
          ...state, 
          chatChannels: payload.chatChannels,
          fetchingPaginatedChannels: false,
          channelPaginationNum: payload.channelPaginationNum
        }

        case 'udpateRequestCount': 
          return {
            ...state,
            userRequestCount: payload.userRequestCount
          }
        case 'setVideoPath':
          return {
            ...state,
            videoPath: payload.videoPath
          }
        case 'handleScreen':
          return {
            ...state,
            fullscreenContent: payload.fullscreenContent,
            expanded: payload.expanded
          }
        case 'updateFullScreenContent':
          return {
            ...state,
            fullscreenContent: null,
          }
        case 'UpdateChatChannelRequestCount': 
          return {
            ...state, 
            userRequestCount: payload.userRequestCount
          }
        case 'updateFilterQuery': 
          return {
            ...state,
            filterQuery: payload.query
          }
        case 'showSearch':
          return {
            ...state,
            searchShowing: payload.searchShowing
          }
        case 'leftChannel':
          return {
            ...state,
            chatChannels: { ...state.chatChannels.filter(channel => channel.id !== payload.leftChannelId)}
          }
        case 'updateChannelFilter': 
          return {
            ...state,
            channelTypeFilter: payload.channelTypeFilter,
            fetchingPaginatedChannels: payload.fetchingPaginatedChannels,
          }
        case 'toggleScreen': 
          return {
            ...state,
            expanded: payload.expanded
          }
        case 'currentMessageLocation':
          return {
            ...state,
            currentMessageLocation: payload.currentMessageLocation
          }
        case 'allMessagesLoaded': 
          return {
            ...state,
            allMessagesLoaded: payload.allMessagesLoaded
          }
        case 'addMessage': 
          return {
            ...state,
            messages: {
              [payload.chatChannelId]: [...payload.messages, ...state.messages[payload.chatChannelId]]
            }
          }
        case 'showMemberList':
          return {
            ...state,
            showMemberlist: payload.showMemberlist
          }
        case 'triggerDeleteMessage':
          return {
            ...state,
            messageDeleteId: payload.messageDeleteId,
            showDeleteModal: payload.showDeleteModal,
          }
        case 'triggerEditMessage': 
          return {
            ...state,
            startEditing: payload.startEditing,
            activeEditMessage: payload.activeEditMessage
          }
        case 'exitVieoContent':
          return {
            ...state,
            videoPath: payload.videoPath,
            fullscreenContent: payload.fullscreenContent,
            expanded: payload.expanded
          }
        case 'updateMessageOnSuccess':
          return {
            ...state,
            messages: payload.messages,
          }
        case 'editMessageClose':
          return {
            ...state,
            startEditing: payload.startEditing,
            markdownEdited: payload.markdownEdited,
            activeEditMessage: payload.activeEditMessage,
          }
        case 'handleAlert':
          return {
            ...state,
            scrolled: payload.scrolled,
            showAlert: payload.showAlert,
          }
        case 'markdownEdited':
          return {
            ...state,
            markdownEdited: payload.markdownEdited
          }
        case 'memberFilterQuery':
          return {
            ...state,
            memberFilterQuery: payload.memberFilterQuery,
          }
        case 'updateDeleteModalState':
          return {
            ...state,
            showDeleteModal: payload.showDeleteModal
          }
        case 'triggerMessageDeleted':
          return {
            ...state,
            messageDeleteId: payload.messageDeleteId,
            showDeleteModal: payload.showDeleteModal
          }
    default:
      return state;
  }
}
