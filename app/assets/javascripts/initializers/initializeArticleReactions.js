/* global sendHapticMessage, showModal */

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
  if (num === '') {
    return 0;
  }
  return parseInt(num, 10);
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
  if (userStatus === 'logged-out') {
    showModal('react-to-article');
    return;
  }
  toggleReaction();
  document.getElementById('reaction-butt-' + reaction).disabled = true;

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
    .then((response) => {
      if (response.status === 200) {
        return response.json().then(() => {
          document.getElementById('reaction-butt-' + reaction).disabled = false;
        });
      }
      toggleReaction();
      document.getElementById('reaction-butt-' + reaction).disabled = false;
      return undefined;
    })
    .catch((error) => {
      toggleReaction();
      document.getElementById('reaction-butt-' + reaction).disabled = false;
    });
}

function setCollectionFunctionality() {
  if (document.getElementById('collection-link-inbetween')) {
    var inbetweenLinks = document.getElementsByClassName(
      'collection-link-inbetween',
    );
    var inbetweenLinksLength = inbetweenLinks.length;
    for (var i = 0; i < inbetweenLinks.length; i += 1) {
      inbetweenLinks[i].onclick = (e) => {
        e.preventDefault();
        var els = document.getElementsByClassName('collection-link-hidden');
        var elsLength = els.length;
        for (var j = 0; j < elsLength; j += 1) {
          els[0].classList.remove('collection-link-hidden');
        }
        for (var k = 0; k < inbetweenLinksLength; k += 1) {
          inbetweenLinks[0].className = 'collection-link-hidden';
        }
      };
    }
  }
}

function requestReactionCounts(articleId) {
  var ajaxReq;
  if (window.XMLHttpRequest) {
    ajaxReq = new XMLHttpRequest();
  } else {
    ajaxReq = new ActiveXObject('Microsoft.XMLHTTP');
  }
  ajaxReq.onreadystatechange = () => {
    if (ajaxReq.readyState === XMLHttpRequest.DONE) {
      var json = JSON.parse(ajaxReq.response);
      json.article_reaction_counts.forEach((reaction) => {
        setReactionCount(reaction.category, reaction.count);
      });
      json.reactions.forEach((reaction) => {
        if (document.getElementById('reaction-butt-' + reaction.category)) {
          showUserReaction(reaction.category, 'not-user-animated');
        }
      });
    }
  };
  ajaxReq.open('GET', '/reactions?article_id=' + articleId, true);
  ajaxReq.send();
}

function jumpToComments() {
  document.getElementById('jump-to-comments').onclick = (e) => {
    e.preventDefault();
    document.getElementById('comments').scrollIntoView({
      behavior: 'instant',
      block: 'start',
    });
  };
}

function initializeArticleReactions() {
  setCollectionFunctionality();

  setTimeout(() => {
    var reactionButts = document.getElementsByClassName(
      'article-reaction-butt',
    );

    // we wait for the article to appear,
    // we also check that reaction buttons are there as draft articles don't have them
    if (document.getElementById('article-body') && reactionButts.length > 0) {
      var articleId = document.getElementById('article-body').dataset.articleId;

      requestReactionCounts(articleId);

      for (var i = 0; i < reactionButts.length; i += 1) {
        reactionButts[i].onclick = function addReactionOnClick(e) {
          reactToArticle(articleId, this.dataset.category);
        };
      }
    }

    if (document.getElementById('jump-to-comments')) {
      jumpToComments();
    }
  }, 3);
}
