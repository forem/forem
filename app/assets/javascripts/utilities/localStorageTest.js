'use strict';

function localStorageTest() {
  var test = 'devtolocalstoragetestforavaialbility';
  try {
    localStorage.setItem(test, test);
    localStorage.removeItem(test);
    return true;
  } catch (e) {
    return false;
  }
}
