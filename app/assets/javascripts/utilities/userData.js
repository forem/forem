'use strict';

function userData() {
  const { user = null } = document.body.dataset;

  return JSON.parse(user);
}
