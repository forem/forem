var waitingOnPostscribe = setInterval(function () {

  if (typeof postscribe === "undefined") {
    return false;
  }

  clearInterval(waitingOnPostscribe);
  var els = document.getElementsByClassName("ltag_gist-liquid-tag");
  for (var i = 0; i < els.length; i++) {
    let current = els[i];
    // eslint-disable-next-line no-undef
    postscribe(current, current.firstElementChild.outerHTML, {
      beforeWrite: function (context) {
        return function (text) {
          if (context.childElementCount > 3) {
            return "";
          }
          return text;
        }
      }(current)
    });
  }
}, 500);