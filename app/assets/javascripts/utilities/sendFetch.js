function sendFetch(switchStatement, body) {
  switch (switchStatement) {
    case 'article-preview':
      return function(csrfToken) {
        return window.fetch('/articles/preview', {
          method: 'POST',
          headers: {
            'X-CSRF-Token': csrfToken,
            Accept: 'application/json',
            'Content-Type': 'application/json',
          },
          body: body,
          credentials: 'same-origin',
        });
      };
    case 'reaction-creation':
      return function(csrfToken) {
        body.append('authenticity_token', csrfToken);
        return window.fetch('/reactions', {
          method: 'POST',
          headers: {
            'X-CSRF-Token': csrfToken,
          },
          body: body,
          credentials: 'same-origin',
        });
      };
    case 'image-upload':
      return function(csrfToken) {
        body.append('authenticity_token', csrfToken);
        return window.fetch('/image_uploads', {
          method: 'POST',
          headers: {
            'X-CSRF-Token': csrfToken,
          },
          body: body,
          credentials: 'same-origin',
        });
      };
    case 'follow-creation':
      return function(csrfToken) {
        body.append('authenticity_token', csrfToken);
        return window.fetch('/follows', {
          method: 'POST',
          headers: {
            'X-CSRF-Token': csrfToken,
          },
          body: body,
          credentials: 'same-origin',
        });
      };
    case 'chat-creation':
      return function(csrfToken) {
        body.append('authenticity_token', csrfToken);
        return window.fetch('/chat_channels/create_chat', {
          method: 'POST',
          headers: {
            'X-CSRF-Token': csrfToken,
          },
          body: body,
          credentials: 'same-origin',
        });
      };
    case 'block-chat':
      return function(csrfToken) {
        body.append('authenticity_token', csrfToken);
        return window.fetch('/chat_channels/block_chat', {
          method: 'POST',
          headers: {
            'X-CSRF-Token': csrfToken,
          },
          body: body,
          credentials: 'same-origin',
        });
      };
    case 'comment-creation':
      return function(csrfToken) {
        return window.fetch('/comments', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': csrfToken,
          },
          body: body,
          credentials: 'same-origin',
        });
      };
    case 'comment-preview':
      return function(csrfToken) {
        return window.fetch('/comments/preview', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': csrfToken,
          },
          body: body,
          credentials: 'same-origin',
        });
      };
    default:
      console.log('A wrong switchStatement was used.');
      break;
  }
  return true;
}
