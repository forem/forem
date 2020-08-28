'use strict';

function userData() {
  const { user = null } = document.body.dataset;

  // [@forem/oss]: there's an edge case in which `user` has the value of "undefined",
  // this results in is a JSON syntax error (`user` should be a hash, not a string).
  if (user === 'undefined') {
    return {};
  }

  return JSON.parse(user);
}
