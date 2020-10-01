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

const applicationHeader = { 'Content-Type': 'application/json' };
const applicationHeaderAccept = {
  Accept: 'application/json',
  ...applicationHeader,
};

function getFetchObject(url, body, headers) {
  return { url: url, headers: headers, body };
}

function getFetchObjectWithToken(url, body) {
  return { url: url, addTokenToBody: true, body };
}

function sendFetch(switchStatement, body) {
  fetchCallback(getFetchCallbackObject(switchStatement, body));
}

function getFetchCallbackObject(switchStatement, body) {
  switch (switchStatement) {
    case 'article-preview':
      return getFetchObject('/articles/preview', body, applicationHeaderAccept);
    case 'reaction-creation':
      return getFetchObjectWithToken('/reactions', body);
    case 'image-upload':
      return getFetchObjectWithToken('/image_uploads', body);
    case 'follow-creation':
      return getFetchObjectWithToken('/follows', body);
    case 'chat-creation':
      return getFetchObjectWithToken('/chat_channels/create_chat', body);
    case 'block-user':
      return getFetchObject('/user_blocks', body, applicationHeaderAccept);
    case 'comment-creation':
      return getFetchObject('/comments', applicationHeader);
    case 'comment-preview':
      return getFetchObject('/comments/preview', body, applicationHeader);
    default:
      console.log('A wrong switchStatement was used.'); // eslint-disable-line no-console
      break;
  }
  return true;
}
