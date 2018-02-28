function initializePreloads() {
  if (document.getElementById("index-container")) {
    setTimeout(function(){
      var articleLinks = document.getElementsByClassName("index-article-link");
      var hrefs = [];
      for(var i=0; i < articleLinks.length; i++) {
        var href = articleLinks[i].href;
        if (instantClick && i < 7 && hrefs.indexOf(href) == -1 ) {
          InstantClick.preload(articleLinks[i].href, "force");
          hrefs.push(href);
        }
      }
    },750);
  }
  else {
    setTimeout(function(){
      if (instantClick) {
        InstantClick.preload(document.getElementById("logo-link").href, "force");
      }
    },2000)
  }
  setTimeout(function(){
      if (instantClick && checkUserLoggedIn()) {
        InstantClick.preload(document.getElementById("notifications-link").href, "force");
      }
  },501)
}