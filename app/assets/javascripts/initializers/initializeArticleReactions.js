//Set reaction count to correct number
function setReactionCount(reactionName, newCount) {
  var reactionClassList = document.getElementById("reaction-butt-" + reactionName).classList;
  var reactionNumber = document.getElementById("reaction-number-" + reactionName);
  if (newCount > 0) {
    reactionClassList.add("activated");
    reactionNumber.innerHTML = newCount;

  }
  else {
    reactionClassList.remove("activated");
    reactionNumber.innerHTML = "";
  }
}

function showUserReaction(reactionName) {
  document.getElementById("reaction-butt-" + reactionName).classList.add("user-activated");
}

function hideUserReaction(reactionName) {
  document.getElementById("reaction-butt-" + reactionName).classList.remove("user-activated");
}

function hasUserReacted(reactionName) {
  return document.getElementById("reaction-butt-" + reactionName)
  .classList.contains("user-activated");

}

function getNumReactions(reactionName) {
  var num = document.getElementById("reaction-number-" + reactionName).innerHTML;
  if (num == "") {
    return 0;
  }
  return parseInt(num);
}

function initializeArticleReactions() {
  setTimeout(function () {
    if (document.getElementById("article-body")) {
      var articleId = document.getElementById("article-body").dataset.articleId;
      if (document.getElementById("article-reaction-actions")) {

        var ajaxReq;
        var thisButt = this;
        if (window.XMLHttpRequest) {
          ajaxReq = new XMLHttpRequest();
        } else {
          ajaxReq = new ActiveXObject("Microsoft.XMLHTTP");
        }
        ajaxReq.onreadystatechange = function () {
          if (ajaxReq.readyState == XMLHttpRequest.DONE) {
            var json = JSON.parse(ajaxReq.response);
            json.article_reaction_counts.forEach(function (reaction) {
              setReactionCount(reaction.category, reaction.count)
            })
            json.reactions.forEach(function (reaction) {
              if (document.getElementById("reaction-butt-" + reaction.category)) {
                showUserReaction(reaction.category);
              }
            })

          }
        }
        ajaxReq.open("GET", "/reactions?article_id=" + articleId, true);
        ajaxReq.send();
      }
    }
    var reactionButts = document.getElementsByClassName("article-reaction-butt")
    for (var i = 0; i < reactionButts.length; i++) {
      reactionButts[i].onclick = function (e) {
        reactToArticle(articleId, this.dataset.category)
      };
    }
    if (document.getElementById('jump-to-comments')) {
      document.getElementById('jump-to-comments').onclick = function(e) {
        e.preventDefault();
        document.getElementById('comments').scrollIntoView({
          behavior: 'instant',
          block: 'start',
        });
      };
    }
  }, 3)
}

function reactToArticle(articleId, reaction) {
  var userStatus = document.getElementsByTagName('body')[0].getAttribute('data-user-status');
  if (userStatus == "logged-out") {
    showModal("react-to-article");
    return;
  } else {
    document.getElementById("reaction-butt-" + reaction).classList.add("user-activated");
  }

  function createFormdata() {
    /*
     * What's not shown here is that "authenticity_token" is included in this formData.
     * The logic can be seen in sendFetch.js.
     */
    var formData = new FormData();
    formData.append("reactable_type", "Article");
    formData.append("reactable_id", articleId);
    formData.append("category", reaction);
    return formData;
  }

  function successCb(response) {
    var numReactions = getNumReactions(reaction);
    if (response.result == "create") {
      showUserReaction(reaction);
      setReactionCount(reaction, numReactions + 1);
    } else {
      hideUserReaction(reaction);
      setReactionCount(reaction, numReactions - 1);
    }
  }

  getCsrfToken()
    .then(sendFetch("reaction-creation", createFormdata()))
    .then(function (response) {
      if (response.status === 200) {
        return response.json().then(successCb);
      } else {
        // there's currently no errorCb.
      }
    })
    .catch(function (error) {
      // there's currently no error handling.
    })
}
