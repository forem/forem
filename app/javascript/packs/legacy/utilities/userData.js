'use strict';

export function userData() {
  const { user = null } = document.body.dataset;

  return JSON.parse(user);
}

window.userData = userData;
