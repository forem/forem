/* global sendHapticMessage, showLoginModal, isTouchDevice, watchForLongTouch */
import { showModalAfterError } from '../utilities/showUserAlertModal';

// Set reaction count to correct number
const setReactionCount = (reactionName, newCount) => {
  const reactionButtons = document.getElementById(
    `reaction-butt-${reactionName}`,
  ).classList;
  const reactionButtonCounter = document.getElementById(
    `reaction-number-${reactionName}`,
  );
  const reactionEngagementCounter = document.getElementById(
    `reaction_engagement_${reactionName}_count`,
  );
  if (newCount > 0) {
    reactionButtons.add('activated');
    reactionButtonCounter.textContent = newCount;
    if (reactionEngagementCounter) {
      reactionEngagementCounter.parentElement.classList.remove('hidden');
      reactionEngagementCounter.textContent = newCount;
    }
  } else {
    reactionButtons.remove('activated');
    reactionButtonCounter.textContent = '0';
    if (reactionEngagementCounter) {
      reactionEngagementCounter.parentElement.classList.add('hidden');
    }
  }
};

const setSumReactionCount = (counts) => {
  const totalCountObj = document.getElementById('reaction_total_count');
  if (totalCountObj && counts.length > 2) {
    let sum = 0;
    for (const count of counts) {
      if (count['category'] != 'readinglist') {
        sum += count['count'];
      }
    }
    totalCountObj.textContent = sum;
  }
};

const showCommentCount = () => {
  const commentCountObj = document.getElementById('reaction-number-comment');
  if (commentCountObj && commentCountObj.dataset.count) {
    commentCountObj.textContent = commentCountObj.dataset.count;
  }
};

const showUserReaction = (reactionName, animatedClass) => {
  const reactionButton = document.getElementById(
    `reaction-butt-${reactionName}`,
  );
  reactionButton.classList.add('user-activated', animatedClass);
  reactionButton.setAttribute('aria-pressed', 'true');

  const reactionDrawerButton = document.getElementById(
    'reaction-drawer-trigger',
  );

  // special-case for readinglist, it's not in the drawer
  if (reactionName === 'readinglist') {
    return;
  }

  reactionDrawerButton.classList.add('user-activated', 'user-animated');
};

const hideUserReaction = (reactionName) => {
  const reactionButton = document.getElementById(
    `reaction-butt-${reactionName}`,
  );
  reactionButton.classList.remove('user-activated', 'user-animated');
  reactionButton.setAttribute('aria-pressed', 'false');
  const reactionDrawerButton = document.getElementById(
    'reaction-drawer-trigger',
  );
  const userActivatedReactions = document
    .querySelector('.reaction-drawer')
    .querySelectorAll('.user-activated');
  if (userActivatedReactions.length == 0) {
    reactionDrawerButton.classList.remove('user-activated', 'user-animated');
  }
};

const hasUserReacted = (reactionName) => {
  return document
    .getElementById(`reaction-butt-${reactionName}`)
    .classList.contains('user-activated');
};

const getNumReactions = (reactionName) => {
  const reactionEl = document.getElementById(`reaction-number-${reactionName}`);
  if (!reactionEl || reactionEl.textContent === '') {
    return 0;
  }

  return parseInt(reactionEl.textContent, 10);
};

const reactToArticle = (articleId, reaction) => {
  const reactionTotalCount = document.getElementById('reaction_total_count');

  const isReadingList = reaction === 'readinglist';

  // Visually toggle the reaction
  function toggleReaction() {
    const currentNum = getNumReactions(reaction);
    if (hasUserReacted(reaction)) {
      hideUserReaction(reaction);
      setReactionCount(reaction, currentNum - 1);
      if (reactionTotalCount && !isReadingList) {
        reactionTotalCount.innerText = Number(reactionTotalCount.innerText) - 1;
      }
    } else {
      showUserReaction(reaction, 'user-animated');
      setReactionCount(reaction, currentNum + 1);
      if (reactionTotalCount && !isReadingList) {
        reactionTotalCount.innerText = Number(reactionTotalCount.innerText) + 1;
      }
    }
  }
  const userStatus = document.body.getAttribute('data-user-status');
  sendHapticMessage('medium');
  if (userStatus === 'logged-out') {
    showLoginModal({
      referring_source: 'reactions_toolbar',
      trigger: reaction,
    });
    return;
  }
  toggleReaction();
  document.getElementById(`reaction-butt-${reaction}`).disabled = true;

  function createFormdata() {
    /*
     * What's not shown here is that "authenticity_token" is included in this formData.
     * The logic can be seen in sendFetch.js.
     */
    const formData = new FormData();
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
          document.getElementById(`reaction-butt-${reaction}`).disabled = false;
        });
      }
      toggleReaction();
      document.getElementById(`reaction-butt-${reaction}`).disabled = false;
      showModalAfterError({
        response,
        element: 'reaction',
        action_ing: 'updating',
        action_past: 'updated',
      });
      return undefined;
    })
    .catch((_error) => {
      toggleReaction();
      document.getElementById(`reaction-butt-${reaction}`).disabled = false;
    });
};

const setCollectionFunctionality = () => {
  if (document.getElementById('collection-link-inbetween')) {
    const inbetweenLinks = document.getElementsByClassName(
      'series-switcher__link--inbetween',
    );
    const inbetweenLinksLength = inbetweenLinks.length;
    for (let i = 0; i < inbetweenLinks.length; i += 1) {
      inbetweenLinks[i].onclick = (e) => {
        e.preventDefault();
        const els = document.getElementsByClassName(
          'series-switcher__link--hidden',
        );
        const elsLength = els.length;
        for (let j = 0; j < elsLength; j += 1) {
          els[0].classList.remove('series-switcher__link--hidden');
        }
        for (let k = 0; k < inbetweenLinksLength; k += 1) {
          inbetweenLinks[0].className = 'series-switcher__link--hidden';
        }
      };
    }
  }
};

const requestReactionCounts = (articleId) => {
  const ajaxReq = new XMLHttpRequest();
  ajaxReq.onreadystatechange = () => {
    if (ajaxReq.readyState === XMLHttpRequest.DONE) {
      const json = JSON.parse(ajaxReq.response);
      setSumReactionCount(json.article_reaction_counts);
      showCommentCount();
      json.article_reaction_counts.forEach((reaction) => {
        setReactionCount(reaction.category, reaction.count);
      });
      json.reactions.forEach((reaction) => {
        if (document.getElementById(`reaction-butt-${reaction.category}`)) {
          showUserReaction(reaction.category, 'not-user-animated');
        }
      });
    }
  };
  ajaxReq.open('GET', `/reactions?article_id=${articleId}`, true);
  ajaxReq.send();
};

const openDrawerOnHover = () => {
  let timer;
  const drawerTrigger = document.getElementById('reaction-drawer-trigger');
  if (!drawerTrigger) {
    return;
  }

  drawerTrigger.addEventListener('click', (_event) => {
    const { articleId } = document.getElementById('article-body').dataset;
    reactToArticle(articleId, 'like');

    drawerTrigger.parentElement.classList.add('open');
  });

  if (isTouchDevice()) {
    watchForLongTouch(drawerTrigger);
    drawerTrigger.addEventListener('longTouch', () => {
      drawerTrigger.parentElement.classList.add('open');
    });
    document.addEventListener('touchstart', (event) => {
      if (!drawerTrigger.parentElement.contains(event.target)) {
        drawerTrigger.parentElement.classList.remove('open');
      }
    });
  } else {
    document.querySelectorAll('.hoverdown').forEach((el) => {
      el.addEventListener('mouseover', function (_event) {
        this.classList.add('open');
        clearTimeout(timer);
      });
      el.addEventListener('mouseout', (_event) => {
        timer = setTimeout((_event) => {
          document.querySelector('.hoverdown.open').classList.remove('open');
        }, 500);
      });
    });
  }
};

const closeDrawerOnOutsideClick = () => {
  document.addEventListener('click', (event) => {
    const reactionDrawerElement = document.querySelector('.reaction-drawer');
    const reactionDrawerTriggerElement = document.querySelector(
      '#reaction-drawer-trigger',
    );
    if (reactionDrawerElement && reactionDrawerTriggerElement) {
      const isClickInside =
        reactionDrawerElement.contains(event.target) ||
        reactionDrawerTriggerElement.contains(event.target);

      const openDrawerElement = document.querySelector('.hoverdown.open');
      if (!isClickInside && openDrawerElement) {
        openDrawerElement.classList.remove('open');
      }
    }
  });
};

const initializeArticleReactions = () => {
  setCollectionFunctionality();

  openDrawerOnHover();
  closeDrawerOnOutsideClick();

  setTimeout(() => {
    const reactionButts = document.getElementsByClassName('crayons-reaction');

    // we wait for the article to appear,
    // we also check that reaction buttons are there as draft articles don't have them
    if (document.getElementById('article-body') && reactionButts.length > 0) {
      const { articleId } = document.getElementById('article-body').dataset;

      requestReactionCounts(articleId);

      for (let i = 0; i < reactionButts.length; i += 1) {
        if (reactionButts[i].classList.contains('pseudo-reaction')) {
          continue;
        }
        reactionButts[i].onclick = function addReactionOnClick(_event) {
          reactToArticle(articleId, this.dataset.category);
        };
      }
    }

    const jumpToCommentsButt = document.getElementById('reaction-butt-comment');
    const commentsSection = document.getElementById('comments');
    if (
      document.getElementById('article-body') &&
      commentsSection &&
      jumpToCommentsButt
    ) {
      jumpToCommentsButt.onclick = function jumpToComments(_event) {
        commentsSection.scrollIntoView({ behavior: 'smooth' });
      };
    }
  }, 3);
};

initializeArticleReactions();
