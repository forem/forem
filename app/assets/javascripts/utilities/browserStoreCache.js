function browserStoreCache(action, userData) {
  try {
    switch (action) {
      case 'set':
        localStorage.setItem('current_user', userData);
        localStorage.setItem(
          'config_body_class',
          JSON.parse(userData).config_body_class,
        );
        break;
      case 'remove':
        localStorage.removeItem('current_user');
        break;
      default:
        return localStorage.getItem('current_user');
    }
  } catch (err) {
    if (navigator.cookieEnabled) {
      browserStoreCache('remove');
    }
  }
}
