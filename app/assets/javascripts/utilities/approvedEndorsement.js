'use strict';

const approveEndorsement = (url, body) => {
  console.log(url, 'rrrrrrrrrrrrrrrrrrrrrrrr')
  const metaTag = document.querySelector("meta[name='csrf-token']");
    return window.fetch(url, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': metaTag.textContent,
      },
      body,
      credentials: 'same-origin',
    });
};
