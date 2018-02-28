const GLOBAL_HANDLER = 'GLOBAL_HANDLER';
const GET_MESSAGE_LIMIT = 30;

class Sendbird {
  constructor(appId) {
    this.self = new window.SendBird({ appId: appId });
    this.messageListQuery = null;
    this.channel = null;
  }

  reset() {
    this.channel = null;
    this.self.removeChannelHandler(GLOBAL_HANDLER);
  }

  /*
  User
   */
  isConnected() {
    return !!this.self.currentUser;
  }

  connect(userId, nickname, action) {
    this.self.connect(userId.trim(), (user, error) => {
      if (error) {
        console.error(error);
        return;
      }
      this.self.updateCurrentUserInfo(nickname.trim(), '', (response, error) => {
        if (error) {
          console.error(error);
          return;
        }
        action();
      });
    });
  }

  disconnect(action) {
    if(this.isConnected()) {
      this.self.disconnect(() => {
        action();
      });
    }
  }

  isCurrentUser(user) {
    return this.self.currentUser.userId == user.userId;
  }

  /*
  Channel
   */
  enterChannel(channelUrl, action) {
    this.self.OpenChannel.getChannel(channelUrl, (channel, error) => {
      if (error) {
        console.error(error);
        return;
      }
      channel.enter((response, error) => {
        if (error) {
          console.error(error);
          return;
        }
        this.channel = channel;
        action();
      });
    });
  }

  exitChannel(callback) {
    this.channel.exit((response, error) => {
      if (error) {
        console.error(error);
        return;
      }
      this.channel = null;
      callback();
    });
  }

  /*
  Message
   */
  getMessageList(action) {
    if (!this.messageListQuery) {
      this.messageListQuery = this.channel.createPreviousMessageListQuery();
    }
    if (this.messageListQuery.hasMore && !this.messageListQuery.isLoading) {
      this.messageListQuery.load(GET_MESSAGE_LIMIT, false, (messageList, error) => {
        if (error) {
          console.error(error);
          return;
        }
        action(messageList);
      });
    }
  }

  sendMessage(textMessage, action) {
    this.channel.sendUserMessage(textMessage, (message, error) => {
      if (error) {
        console.error(error);
        return;
      }
      action(message);
    });
  }

  /*
  Handler
   */
  createHandler(messageReceivedFunc) {
    let channelHandler = new this.self.ChannelHandler();
    channelHandler.onMessageReceived = (channel, message) => {
      messageReceivedFunc(channel, message);
    };
    channelHandler.onMessageDeleted = (channel, messageId) => {
      var deletedMessage = document.getElementById(messageId);
      if (deletedMessage) {
        deletedMessage.remove();
      }
    };
    this.self.addChannelHandler(GLOBAL_HANDLER, channelHandler);
  }
}

export { Sendbird as default };
