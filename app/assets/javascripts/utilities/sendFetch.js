'use strict';

const fetchCallback = ({ url, headers = {}, addTokenToBody = false, body }) => {
  return (csrfToken) => {
    if (addTokenToBody) {
      body.append('authenticity_token', csrfToken);
    }
    return window.fetch(url, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        ...headers,
      },
      body,
      credentials: 'same-origin',
    });
  };
};

function sendFetch(switchStatement, body) {
  switch (switchStatement) {
    case 'article-preview':
      return fetchCallback({
        url: '/articles/preview',
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
        },
        body,
      });
    case 'reaction-creation':
      return fetchCallback({
        url: '/reactions',
        addTokenToBody: true,
        body,
      });
    case 'image-upload':
      return fetchCallback({
        url: '/image_uploads',
        addTokenToBody: true,
        body,
      });
    case 'follow-creation':
      return fetchCallback({
        url: '/follows',
        addTokenToBody: true,
        body,
      });
    case 'chat-creation':
      return fetchCallback({
        url: '/chat_channels/create_chat',
        addTokenToBody: true,
        body,
      });
    case 'block-user':
      return fetchCallback({
        url: '/user_blocks',
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
        },
        addTokenToBody: false,
        body,
      });
    case 'comment-creation':
      return fetchCallback({
        url: '/comments',
        headers: {
          'Content-Type': 'application/json',
        },
        body,
      });
    case 'comment-preview':
      return fetchCallback({
        url: '/comments/preview',
        headers: {
          'Content-Type': 'application/json',
        },
        body,
      });
    default:
      console.log('A wrong switchStatement was used.'); // eslint-disable-line no-console
      break;
  }
  return true;
}
