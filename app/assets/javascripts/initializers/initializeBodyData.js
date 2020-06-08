

/* global checkUserLoggedIn */

function removeExistingCSRF() {
  var csrfTokenMeta = document.querySelector("meta[name='csrf-token']");
  var csrfParamMeta = document.querySelector("meta[name='csrf-param']");
  if (csrfTokenMeta && csrfParamMeta) {
    csrfTokenMeta.parentNode.removeChild(csrfTokenMeta);
    csrfParamMeta.parentNode.removeChild(csrfParamMeta);
  }
}

function fetchBaseData() {
  var xmlhttp;
  if (window.XMLHttpRequest) {
    xmlhttp = new XMLHttpRequest();
  } else {
    xmlhttp = new ActiveXObject('Microsoft.XMLHTTP');
  }
  xmlhttp.onreadystatechange = () => {
    if (xmlhttp.readyState === XMLHttpRequest.DONE) {
      // Assigning CSRF
      var json = JSON.parse(xmlhttp.responseText);
      if (json.token) {
        removeExistingCSRF();
      }
      var newCsrfParamMeta = document.createElement('meta');
      newCsrfParamMeta.name = 'csrf-param';
      newCsrfParamMeta.content = json.param;
      document.getElementsByTagName('head')[0].appendChild(newCsrfParamMeta);
      var newCsrfTokenMeta = document.createElement('meta');
      newCsrfTokenMeta.name = 'csrf-token';
      newCsrfTokenMeta.content = json.token;
      document.getElementsByTagName('head')[0].appendChild(newCsrfTokenMeta);
      document.getElementsByTagName('body')[0].dataset.loaded = 'true';

      // Assigning Broadcast
      if (json.broadcast) {
        document.body.dataset.broadcast = json.broadcast;
      }

      // Assigning User
      if (checkUserLoggedIn()) {
        document.getElementsByTagName('body')[0].dataset.user = json.user;
        browserStoreCache('set', json.user);
        setTimeout(() => {
          if (typeof ga === 'function') {
            ga('set', 'userId', JSON.parse(json.user).id);
          }
        }, 400);
      }
    }
  };

  xmlhttp.open('GET', '/async_info/base_data', true);
  xmlhttp.send();
}

function initializeBodyData() {
  fetchBaseData();
}
