
function initializeTouchDevice() {
  var isTouchDevice = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
  setTimeout(function(){
    removeShowingMenu();
    if (isTouchDevice) {
      document.getElementById("navigation-butt").onclick = function(e){
        document.getElementById("navbar-menu-wrapper").classList.toggle('showing');
      }
    } else {
      document.getElementById("navbar-menu-wrapper").classList.add('desktop')
    }
  },10)
}


function removeShowingMenu() {  
  document.getElementById("navbar-menu-wrapper").classList.remove('showing')
  setTimeout(function(){
    document.getElementById("navbar-menu-wrapper").classList.remove('showing')
  },5)
  setTimeout(function(){
    document.getElementById("navbar-menu-wrapper").classList.remove('showing')
  },150)
}
