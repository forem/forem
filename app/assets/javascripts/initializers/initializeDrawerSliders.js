function initializeDrawerSliders() {
  if(!initializeSwipeGestures.called) {
    swipeState = "middle";
    initializeSwipeGestures();
  }
  if (document.getElementById("on-page-nav-controls")){
    if (document.getElementById("sidebar-wrapper-left")){
      document.getElementById("sidebar-wrapper-left").onclick = function(e){
        if (e.target.closest(".side-bar")) return;
        swipeState = "middle";
        slideSidebar("left","outOfView");
      }
    }

    if (document.getElementById("sidebar-wrapper-right")){
      document.getElementById("sidebar-wrapper-right").onclick = function(e){
        if (e.target.closest(".side-bar")) return;
        swipeState = "middle";
        slideSidebar("right","outOfView");
      }
    }

    if (document.getElementById("on-page-nav-butt-left")){
      document.getElementById("on-page-nav-butt-left").onclick = function(){
        swipeState = "left"
        slideSidebar("left","intoView");
      }
    }
    if (document.getElementById("on-page-nav-butt-right")){
      document.getElementById("on-page-nav-butt-right").onclick = function(){
        swipeState = "right"
        slideSidebar("right","intoView");
      }
    }
    InstantClick.on('change', function() {
      document.getElementsByTagName('body')[0].classList.remove('modal-open');
      slideSidebar("right","outOfView");
      slideSidebar("left","outOfView");
    });
    listenForNarrowMenuClick();
  }
}

function listenForNarrowMenuClick(event) {
  var navLinks = document.getElementsByClassName("narrow-nav-menu");
  var narrowFeedButt = document.getElementById("narrow-feed-butt");
  for (var i = 0; i < navLinks.length; i++) {
    document.getElementById("narrow-nav-menu").classList.remove("showing");
  }
  if (narrowFeedButt) {
    narrowFeedButt.onclick = function(){
      document.getElementById("narrow-nav-menu").classList.add("showing");
    }
  }
  for (var i = 0; i < navLinks.length; i++) {
    navLinks[i].onclick = function(event){
      document.getElementById("narrow-nav-menu").classList.remove("showing");
    }
  }
}
