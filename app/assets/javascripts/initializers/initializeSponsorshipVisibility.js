function initializeSponsorshipVisibility() {
  var el = document.getElementById("sponsorship-widget");
  var user = userData();
  if (el && user && user.display_sponsors){
    el.classList.add("showing");
    setTimeout(function(){
      if (window.ga) {
        var links = document.getElementsByClassName("partner-link");
        for(var i = 0; i < links.length; i++) {
          links[i].onclick = function(event){
            ga('send', 'event', 'click', 'click sponsor link', event.target.dataset.details, null);
          }
        }
      }
    },400)
  } else if (el && user) {
    el.classList.remove("showing");
  }
}