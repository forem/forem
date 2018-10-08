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
              if (reaction.count > 0) {
                document.getElementById("reaction-butt-" + reaction.category).classList.add("activated")
                document.getElementById("reaction-number-" + reaction.category).innerHTML = reaction.count;
              }
            })
            json.reactions.forEach(function (reaction) {
              if (document.getElementById("reaction-butt-" + reaction.category)) {
                document.getElementById("reaction-butt-" + reaction.category).classList.add("user-activated")
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
    document.getElementById("reaction-butt-" + reaction).classList.add("user-activated")
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
    var num = document.getElementById("reaction-number-" + reaction).innerHTML;
    if (response.result == "create") {
      document.getElementById("reaction-butt-" + reaction).classList.add("user-activated")
      if (num == "") {
        document.getElementById("reaction-number-" + reaction).innerHTML = "1";
      } else {
        document.getElementById("reaction-number-" + reaction).innerHTML = parseInt(num) + 1;
      }
    } else {
      document.getElementById("reaction-butt-" + reaction).classList.remove("user-activated")
      if (num == 1) {
        document.getElementById("reaction-butt-" + reaction).classList.remove("activated")
        document.getElementById("reaction-number-" + reaction).innerHTML = "";
      } else {
        document.getElementById("reaction-number-" + reaction).innerHTML = parseInt(num) - 1;
      }
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