var scrollInterval;
var lastPressedKey;
var lastPressTime;
var codeToWord = {191: "find"}
function initializeKeyListeners() {
  document.addEventListener('keydown', function(e) {
    if (document.activeElement.tagName != "INPUT" && document.activeElement.tagName != "TEXTAREA" && !document.activeElement.classList.contains("input")) {
      reactToEvent(e)
    }
  });
}

function reactToEvent(event){
  if (codeToWord[event.which] === "find"){
    event.preventDefault();
    var searchBox = document.getElementById("nav-search")
    searchBox.focus();
    searchBox.select();
  }
}
