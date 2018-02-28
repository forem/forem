function initializeSettings(){
  if (document.getElementById("settings-org-secret")){
    document.getElementById("settings-org-secret").onclick = function(event){
      event.target.select()
    }
  }
}