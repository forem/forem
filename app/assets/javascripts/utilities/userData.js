'use strict';

function userData() {
  const { user = null } = document.body.dataset;

  if (!user) {
    return null;
  }
  
  try {
    return JSON.parse(user);
  } catch (error) {
    console.error('Error parsing user data:', error);
    return null;
  }
}
