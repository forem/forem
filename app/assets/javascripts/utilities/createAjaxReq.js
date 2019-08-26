'use strict';

function createAjaxReq() {
  if (window.XMLHttpRequest) {
    return new XMLHttpRequest();
  }
  return new window.ActiveXObject('Microsoft.XMLHTTP');
}
