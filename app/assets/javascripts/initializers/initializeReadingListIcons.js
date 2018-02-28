function initializeReadingListIcons() {
  var readingListButtons = document.getElementsByClassName("bookmark-engage");
  for(var i = 0; i < readingListButtons.length; i++) {
    highlightButton(readingListButtons[i]);
  }
  addReadingListCountToHomePage();
}

//private

function highlightButton(button){
  var user = userData();
  var buttonIdInt = parseInt(button.dataset.reactableId)
  if (user && user.reading_list_ids.indexOf(buttonIdInt) > -1 ){
    button.classList.add("selected");
  }
  else {
    button.classList.remove("selected");
  }
  button.addEventListener("click", reactToReadingListButtonClick);
}

function addReadingListCountToHomePage(){
  var user = userData();
  if ( user && document.getElementById("reading-list-count") ) {
    var readingListCount = user.reading_list_ids.length > 0 ? user.reading_list_ids.length : "EMPTY"
    document.getElementById("reading-list-count").innerHTML = "("+readingListCount+")"
    document.getElementById("reading-list-count").dataset.count = user.reading_list_ids.length
  }
}

function reactToReadingListButtonClick(event){
  event.preventDefault();
  var userStatus = document.getElementsByTagName('body')[0].getAttribute('data-user-status');
  if (userStatus == "logged-out") {
    showModal("add-to-readinglist-from-index");
    return;
  }
  var button = properButtonFromEvent(event);
  renderOptimisticResult(button);
  getCsrfToken()
      .then(sendFetch("reaction-creation", buttonFormData(button)))
      .then(function (response) {
        if (response.status === 200) {
          return response.json().then(function(json){
            renderButtonState(button, json);
            renderNewSidebarCount(button,json);
          });
        } else {
          // there's currently no errorCb.
        }
      })
      .catch(function (error) {
        // there's currently no error handling.
      })
}

function renderButtonState(button, json) {
  if (json.result === "create") {
    button.classList.add("selected");
  }
  else {
    button.classList.remove("selected")
  }
}

function renderNewSidebarCount(button,json) {
  var count = parseInt(document.getElementById("reading-list-count").dataset.count)
  if (json.result === "create") {
    newCount = count + 1;
  }
  else {
    if ( count != 0 ){
      newCount = count - 1;
    }
  }
  document.getElementById("reading-list-count").dataset.count = newCount;
  document.getElementById("reading-list-count").innerHTML = "("+newCount+")"
}


function buttonFormData(button){
  var formData = new FormData();
  formData.append("reactable_type", "Article");
  formData.append("reactable_id", button.dataset.reactableId);
  formData.append("category", "readinglist");
  return formData;
}

function renderOptimisticResult(button){
  renderButtonState(button, {result: "create"}); //optimistic create only for now
}

function properButtonFromEvent(event){
  var properElement;
  if (event.target.tagName == "BUTTON") {
    properElement = event.target;
  }
  else {
    properElement = event.target.parentElement;
  }
  return properElement;
}