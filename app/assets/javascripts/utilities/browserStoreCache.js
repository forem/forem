function browserStoreCache(action, userData) {
  try {
    if (action === 'set') {
      localStorage.setItem('current_user', userData);
      localStorage.setItem('config_body_class', JSON.parse(userData)['config_body_class']);
    } else if (action === 'remove') {
      localStorage.removeItem('current_user');
    } else {
      return localStorage.getItem('current_user');
    }
  } catch (err) {
    browserStoreCache('remove');
  }
}
