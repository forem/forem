import { LiveChat } from '../src-sendbird/chat';
import { getUserData } from '../src/utils/getUserData';

HTMLDocument.prototype.ready = new Promise((resolve) => {
  if (document.readyState !== 'loading') { return resolve(); }
  document.addEventListener('DOMContentLoaded', () => resolve());
});

document.ready
  .then(getUserData()
    .then(() => {
      if (document.getElementById('sb_chat')) {
        const userData = JSON.parse(document.body.getAttribute('data-user'));
        const livechatData = document.getElementById('sb_chat').dataset;
        const appId = livechatData.sendbirdAppId;
        const channelUrl = livechatData.sendbirdLivechatUrl;
        const userId = userData.id.toString();
        const nickname = userData.username;
        window.liveChat.startWithConnect(appId, userId, nickname, () => {
          window.liveChat.enterChannel(channelUrl, () => {
          });
        });
      }
    }));
