'use strict';

const approveEndorsement = (url, id) => {
  console.log(url, 'rrrrrrrrrrrrrrrrrrrrrrrr')
  console.log(id, `${url}/${id}`);
  const metaTag = document.querySelector("meta[name='csrf-token']");

  const formData = new FormData();
  formData.append('id', id);
  window.fetch(`${url}/${id}`, {
    method: 'PATCH',
    headers: {
      'X-CSRF-Token': metaTag.getAttribute('content'),
    },
    body: formData,
    credentials: 'same-origin',
  });
};
