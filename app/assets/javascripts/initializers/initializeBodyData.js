function initializeBodyData() {
  fetchBaseData();
}

function fetchBaseData() {
  var xmlhttp;
  if (window.XMLHttpRequest) {
    xmlhttp = new XMLHttpRequest();
  } else {
    xmlhttp = new ActiveXObject('Microsoft.XMLHTTP');
  }
  xmlhttp.onreadystatechange = function() {
    if (xmlhttp.readyState == XMLHttpRequest.DONE) {
      var json = JSON.parse(xmlhttp.responseText);
      if (json.token) {
        removeExistingCSRF();
      }
      var meta = document.createElement('meta');
      var metaTag = document.querySelector("meta[name='csrf-token']");
      meta.name = 'csrf-param';
      meta.content = json.param;
      document.getElementsByTagName('head')[0].appendChild(meta);
      var meta = document.createElement('meta');
      meta.name = 'csrf-token';
      meta.content = json.token;
      document.getElementsByTagName('head')[0].appendChild(meta);
      document.getElementsByTagName('body')[0].dataset.loaded = 'true';
      if (checkUserLoggedIn()) {
        document.getElementsByTagName('body')[0].dataset.user = json.user;
        browserStoreCache('set', json.user);
        setTimeout(function() {
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

function removeExistingCSRF() {
  var csrfTokenMeta = document.querySelector("meta[name='csrf-token']");
  var csrfParamMeta = document.querySelector("meta[name='csrf-param']");
  if (csrfTokenMeta && csrfParamMeta) {
    csrfTokenMeta.parentNode.removeChild(csrfTokenMeta);
    csrfParamMeta.parentNode.removeChild(csrfParamMeta);
  }
}
