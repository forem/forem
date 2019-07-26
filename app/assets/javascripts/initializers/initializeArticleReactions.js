// Set reaction count to correct number
function setReactionCount(reactionName, newCount) {
  var reactionClassList = document.getElementById(
    'reaction-butt-' + reactionName,
  ).classList;
  var reactionNumber = document.getElementById(
    'reaction-number-' + reactionName,
  );
  if (newCount > 0) {
    reactionClassList.add('activated');
    reactionNumber.textContent = newCount;
  } else {
    reactionClassList.remove('activated');
    reactionNumber.textContent = '0';
  }
}

function showUserReaction(reactionName, animatedClass) {
  document
    .getElementById('reaction-butt-' + reactionName)
    .classList.add('user-activated', animatedClass);
}

function hideUserReaction(reactionName) {
  document
    .getElementById('reaction-butt-' + reactionName)
    .classList.remove('user-activated', 'user-animated');
}

function hasUserReacted(reactionName) {
  return document
    .getElementById('reaction-butt-' + reactionName)
    .classList.contains('user-activated');
}

function getNumReactions(reactionName) {
  var num = document.getElementById('reaction-number-' + reactionName)
    .textContent;
  if (num == '') {
    return 0;
  }
  return parseInt(num);
}

function initializeArticleReactions() {
  setTimeout(function() {
    if (document.getElementById('article-body')) {
      var articleId = document.getElementById('article-body').dataset.articleId;
      if (document.getElementById('article-reaction-actions')) {
        var ajaxReq;
        var thisButt = this;
        if (window.XMLHttpRequest) {
          ajaxReq = new XMLHttpRequest();
        } else {
          ajaxReq = new ActiveXObject('Microsoft.XMLHTTP');
        }
        ajaxReq.onreadystatechange = function() {
          if (ajaxReq.readyState == XMLHttpRequest.DONE) {
            var json = JSON.parse(ajaxReq.response);
            json.article_reaction_counts.forEach(function(reaction) {
              setReactionCount(reaction.category, reaction.count);
            });
            json.reactions.forEach(function(reaction) {
              if (
                document.getElementById('reaction-butt-' + reaction.category)
              ) {
                showUserReaction(reaction.category, 'not-user-animated');
              }
            });
          }
        };
        ajaxReq.open('GET', '/reactions?article_id=' + articleId, true);
        ajaxReq.send();
      }
    }
    var reactionButts = document.getElementsByClassName(
      'article-reaction-butt',
    );
    for (var i = 0; i < reactionButts.length; i++) {
      reactionButts[i].onclick = function(e) {
        reactToArticle(articleId, this.dataset.category);
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
  }, 3);
}

function reactToArticle(articleId, reaction) {
  // Visually toggle the reaction
  function toggleReaction() {
    var currentNum = getNumReactions(reaction);
    if (hasUserReacted(reaction)) {
      hideUserReaction(reaction);
      setReactionCount(reaction, currentNum - 1);
    } else {
      showUserReaction(reaction, 'user-animated');
      setReactionCount(reaction, currentNum + 1);
    }
  }
  var userStatus = document
    .getElementsByTagName('body')[0]
    .getAttribute('data-user-status');
  sendHapticMessage('medium');
  if (userStatus == 'logged-out') {
    showModal('react-to-article');
    return;
  } else {
    toggleReaction();
    document.getElementById('reaction-butt-' + reaction).disabled = true;
  }

  function createFormdata() {
    /*
     * What's not shown here is that "authenticity_token" is included in this formData.
     * The logic can be seen in sendFetch.js.
     */
    var formData = new FormData();
    formData.append('reactable_type', 'Article');
    formData.append('reactable_id', articleId);
    formData.append('category', reaction);
    return formData;
  }

  getCsrfToken()
    .then(sendFetch('reaction-creation', createFormdata()))
    .then(function(response) {
      if (response.status === 200) {
        return response.json().then(() => {
          document.getElementById('reaction-butt-' + reaction).disabled = false;
        });
      } else {
        toggleReaction();
        document.getElementById('reaction-butt-' + reaction).disabled = false;
      }
    })
    .catch(function(error) {
      toggleReaction();
      document.getElementById('reaction-butt-' + reaction).disabled = false;
    });
}
