/*
  global userData, globalFeatureFlagEnabled, I18n, sendHapticMessage,
  showLoginModal, getCsrfToken, sendFetch, showModalAfterError,
  addLocalizedDateTimeToElementsTitles
*/

function buildCommentFormHTML(commentableId, commentableType, parentId) {
  var authToken = document
    .querySelector("meta[name='csrf-token']")
    .getAttribute('content');
  var user = userData();
  var codeOfConductHTML = '';
  if (user && !user.codeOfConduct && user.commentCount < 1) {
    codeOfConductHTML =
      '<div class="code-of-conduct sub-comment-code-of-conduct" style="display:block" id="toggle-code-of-conduct-checkbox">\
                            <input class="checkbox" type="checkbox" name="checked_code_of_conduct" required />\
                            <label for="checked_code_of_conduct">I\'ve read the <a href="/code-of-conduct">code of conduct</a></label>\
                          </div>';
  }
  var randomIdNumber = Math.floor(Math.random() * 1991); // eslint-disable-line no-unused-vars

  return `<form class="comment-form pt-4" onsubmit="handleCommentSubmit.bind(this)(event)" id="new-comment-${parentId}" action="/comments" accept-charset="UTF-8" method="post" data-comment-id="${parentId}">
      <input name="utf8" type="hidden" value="&#x2713;" />
      <input type="hidden" name="authenticity_token" value="${authToken}">
      <input value="${commentableId}" type="hidden" name="comment[commentable_id]" id="comment_commentable_id" />
      <input value="${commentableType}" type="hidden" name="comment[commentable_type]" id="comment_commentable_type" />
      <input value="${parentId}" type="hidden" name="comment[parent_id]" id="comment_parent_id" />
      <div class="comment-form__inner">
        <div class="comment-form__field">
          <textarea id="textarea-for-${parentId}" class="crayons-textfield crayons-textfield--ghost comment-textarea" name="comment[body_markdown]" data-tracking-name="comment_form_textfield" placeholder="Reply..." aria-label="Reply to a comment..." required="required" onkeydown="handleKeyDown(event)" onfocus="handleFocus(event)" oninput="handleChange(event)" onkeyup="handleKeyUp(event)"></textarea>
        </div>
        <div class="response-templates-container crayons-card crayons-card--secondary p-4 mb-4 fs-base comment-form__templates hidden">
          <header>
            <button type="button" class="personal-template-button active" data-target-type="personal" data-form-id="new_comment">Personal</button>
            <button type="button" class="moderator-template-button hidden" data-target-type="moderator" data-form-id="new_comment">Trusted User</button>
          </header>
          <div class="personal-responses-container"></div>
          <div class="moderator-responses-container hidden"></div>
          <a target="_blank" rel="noopener nofollow" href="/settings/response-templates">Create template</a>
          <p>Templates let you quickly answer FAQs or store snippets for re-use.</p>
        </div>
        <div class="comment-form__preview text-styles text-styles--secondary"></div>
        <div class="comment-form__buttons mb-4 flex items-center">
          <button type="submit" class="crayons-btn comment-action-button mr-2 js-btn-enable" name="submit" data-tracking-name="comment_reply_submit_button" disabled>Submit</button>
          <button type="button" class="preview-toggle crayons-btn crayons-btn--secondary comment-action-button comment-action-preview mr-2 js-btn-enable" data-tracking-name="comment_reply_preview_button" onclick="handleCommentPreview(event)" disabled>Preview</button>
          <button type="button" class="crayons-btn crayons-btn--ghost ml-auto" data-tracking-name="comment_reply_dismiss_button" onclick="handleFormClose(event)">Dismiss</button>
        </div>
      </div>
    </form>`;
}

function reply(comment) {
  var iconSmallComment = `<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" class="crayons-icon reaction-icon not-reacted"><path d="M10.5 5h3a6 6 0 110 12v2.625c-3.75-1.5-9-3.75-9-8.625a6 6 0 016-6zM12 15.5h1.5a4.501 4.501 0 001.722-8.657A4.5 4.5 0 0013.5 6.5h-3A4.5 4.5 0 006 11c0 2.707 1.846 4.475 6 6.36V15.5z"/></svg>`;
  var replyButton = `<button class="js actions crayons-btn crayons-btn--ghost crayons-btn--s crayons-btn--icon-left toggle-reply-form mr-1 inline-flex"
    data-comment-id="${comment.id}"
    data-path="${comment.url}"
    data-tracking-name="comment_reply_button">
    ${iconSmallComment}
    <span class="hidden m:inline-block">Reply</span>
  </button>`;
  if (comment.newly_created) {
    return replyButton;
  }
}

function react(comment) {
  var reactedClass = ''; // eslint-disable-line no-unused-vars
  var num = 0;
  var iconSmallHeart = `<svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" class="crayons-icon reaction-icon not-reacted"><path d="M18.884 12.595l.01.011L12 19.5l-6.894-6.894.01-.01A4.875 4.875 0 0112 5.73a4.875 4.875 0 016.884 6.865zM6.431 7.037a3.375 3.375 0 000 4.773L12 17.38l5.569-5.569a3.375 3.375 0 10-4.773-4.773L9.613 10.22l-1.06-1.062 2.371-2.372a3.375 3.375 0 00-4.492.25v.001z"/></svg>`;
  var iconSmallHeartFilled = `<svg width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" class="crayons-icon reaction-icon--like reaction-icon reacted"><path d="M5.116 12.595a4.875 4.875 0 015.56-7.68h-.002L7.493 8.098l1.06 1.061 3.181-3.182a4.875 4.875 0 016.895 6.894L12 19.5l-6.894-6.894.01-.01z"/></svg>`;

  if (comment.newly_created) {
    num = 1;
  } else {
    num = comment.public_reactions_count;
  }

  if (comment.newly_created || comment.heart_ids.indexOf(userData().id) > -1) {
    reactedClass = 'reacted';
  }

  var reactButton = `<button class="crayons-tooltip__activator crayons-btn crayons-btn--ghost crayons-btn--icon${
    num === 0 ? '' : '--left'
  } crayons-btn--s mr-1 reaction-like inline-flex reaction-button" id="button-for-comment-${
    comment.id
  }" data-comment-id="${comment.id}" data-tracking-name="comment_heart_button">
    ${iconSmallHeart}
    ${iconSmallHeartFilled}
    <span class="reactions-count" id="reactions-count-${comment.id}">${num}</span>
    ${
      num > 0
        ? '<span class="reactions-label hidden m:inline-block">like</span>'
        : ''
    }
    <span data-testid="tooltip" class="crayons-tooltip__content">Like</span>
  </button>`;

  return reactButton;
}

function buildCommentHTML(comment) {
  var iconSmallOverflowHorizontal = `<svg width="24" height="24" viewBox="0 0 24 24" class="crayons-icon pointer-events-none" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" clip-rule="evenodd" d="M8.25 12a1.5 1.5 0 11-3 0 1.5 1.5 0 013 0zm5.25 0a1.5 1.5 0 11-3 0 1.5 1.5 0 013 0zm3.75 1.5a1.5 1.5 0 100-3 1.5 1.5 0 000 3z" /></svg>`;
  var iconCollapse = `<svg width="24" height="24" class="crayons-icon expanded" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12 10.6771L8 6.93529L8.99982 6L12 8.80653L15.0002 6L16 6.93529L12 10.6771ZM12 15.1935L8.99982 18L8 17.0647L12 13.3229L16 17.0647L15.0002 17.9993L12 15.1935Z" /></svg>`;
  var iconExpand = `<svg width="24" height="24" class="crayons-icon collapsed" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12 18L8 14.2287L8.99982 13.286L12 16.1147L15.0002 13.286L16 14.2287L12 18ZM12 7.88533L8.99982 10.714L8 9.77133L12 6L16 9.77133L15.0002 10.7133L12 7.88533Z" /></svg>`;

  var depthClass = '';
  var customClass = ''; // eslint-disable-line no-unused-vars

  var detailsStartHTML = '';
  var detailsEndHTML = '';

  var commentHeader = '';
  var commentFooter = '';
  var commentAvatar = '';
  var commentBody = '';
  var subscriptionIcon = '';
  var communityLeaderIcon = '';

  if (comment.depth == 0) {
    depthClass += 'root ';
  } else {
    depthClass += 'child ';
  }

  if (comment.depth > 3) {
    depthClass += 'comment--too-deep ';
  }

  if (comment.newly_created) {
    customClass = 'comment-created-via-fetch';
  }

  if (comment.user.cached_base_subscriber) {
    subscriptionIcon = ` <img class='subscription-icon' src='${document.body.dataset.subscriptionIcon}' alt='Subscriber' />`;
  }
  if (
    comment.user.cached_community_leader &&
    globalFeatureFlagEnabled('community_favorites')
  ) {
    communityLeaderIcon = ` <img class='community-leader-icon' src='${document.body.dataset.communityLeaderIcon}' alt='Community Leader' />`;
  }

  if (comment.depth < 3) {
    detailsStartHTML = `
      <details class="comment-wrapper comment-wrapper--deep-${
        comment.depth
      } js-comment-wrapper" open>
        <summary aria-label="Toggle this comment (and replies)" data-tracking-name="expand_comment_toggle">
          <span class="inline-block align-middle ${
            comment.depth > 0 ? 'mx-0' : 'm:mx-1'
          }">
            ${iconCollapse}
            ${iconExpand}
          </span>
          <span class="js-collapse-comment-content inline-block align-middle"></span>
        </summary>
    `;
    detailsEndHTML = `</details>`;
  }

  commentAvatar = `<a href="/${
    comment.user.username
  }" class="shrink-0 crayons-avatar ${
    comment.depth == 0 ? 'm:crayons-avatar--l mt-4 m:mt-3' : 'mt-4'
  }">
    <img class="crayons-avatar__image" width="32" height="32" src="${
      comment.user.profile_pic
    }" alt="${comment.user.username} profile" />
  </a>`;

  commentHeader = `<div class="comment__header" >
    <a href="/${
      comment.user.username
    }" class="crayons-link crayons-link--secondary flex items-center fw-medium m:hidden">
      <span class="js-comment-username">${comment.user.name}</span>
    </a>
    <div class="profile-preview-card relative mb-4 s:mb-0 fw-medium hidden m:block">
      <button id="comment-profile-preview-trigger-${
        comment.id
      }" aria-controls="comment-profile-preview-content-${
    comment.id
  }" class="profile-preview-card__trigger p-1 -my-1 -ml-1 crayons-btn crayons-btn--ghost" aria-label="${
    comment.user.name
  } profile details">${
    comment.user.name
  }${subscriptionIcon}${communityLeaderIcon}</button>
      <span data-js-comment-user-id="${
        comment.user.id
      }" data-js-dropdown-content-id="comment-profile-preview-content-${
    comment.id
  }" class="preview-card-placeholder"></span>
    </div>
    <span class="color-base-30 px-2 m:pl-0" role="presentation">&bull;</span>

    <a href="${
      comment.url
    }" class="comment-date crayons-link crayons-link--secondary fs-s">
      <time datetime="${comment.published_timestamp}" class="date-no-year">
        ${comment.readable_publish_date}
      </time>
    </a>

    <div class="comment__dropdown" data-tracking-name="comment_dropdown">
      <button  id="comment-dropdown-trigger-${
        comment.id
      }" aria-controls="comment-dropdown-${
    comment.id
  }" aria-expanded="false" class="dropbtn comment__dropdown-trigger crayons-btn crayons-btn--s crayons-btn--ghost crayons-btn--icon" aria-label="Toggle dropdown menu" aria-haspopup="true">
        ${iconSmallOverflowHorizontal}
      </button>
      <div id="comment-dropdown-${
        comment.id
      }" class="crayons-dropdown right-1 s:right-0 s:left-auto fs-base dropdown">
        <ul class="m-0">
          <li><a href="${
            comment.url
          }" class="crayons-link crayons-link--block permalink-copybtn" aria-label="Copy link to ${
    comment.user.name
  }'s comment" data-no-instant>${I18n.t('core.copy_link')}</a></li>
          <li><a href="${
            comment.url
          }/settings" class="crayons-link crayons-link--block" aria-label="Go to ${
    comment.user.name
  }'s comment settings">Settings</a></li>
          <li><a href="/report-abuse?url=${
            comment.url
          }" class="crayons-link crayons-link--block" aria-label="Report ${
    comment.user.name
  }'s comment as abusive or violating our code of conduct and/or terms and conditions">${I18n.t(
    'core.report_abuse',
  )}</a></li>
          <li class="${comment.newly_created ? '' : 'hidden'}"><a href="${
    comment.url
  }/edit" class="crayons-link crayons-link--block" rel="nofollow" aria-label="Edit this comment">Edit</a></li>
          <li class="${
            comment.newly_created ? '' : 'hidden'
          }"><a data-no-instant="" href="${
    comment.url
  }/delete_confirm" class="crayons-link crayons-link--block" rel="nofollow" aria-label="Delete this comment">Delete</a></li>
        </ul>
      </div>
    </div>
  </div>`;

  commentFooter = `<footer class="comment__footer">
    ${react(comment)}
    ${reply(comment)}
  </footer>`;

  commentBody = `${detailsStartHTML}
    <div class="comment single-comment-node ${depthClass} comment--deep-${comment.depth}" id="comment-node-${comment.id}" data-comment-id="${comment.id}" data-path="${comment.url}" data-comment-author-id="${comment.user.id}" data-current-user-comment="${comment.newly_created}" data-content-user-id="${comment.user.id}">
      <div class="comment__inner">
        ${commentAvatar}
        <div class="inner-comment comment__details">
          <div class="comment__content crayons-card">
            ${commentHeader}
            <div class="comment__body text-styles text-styles--secondary body">
              ${comment.body_html}
            </div>
          </div>
          ${commentFooter}
        </div>
      </div>
    </div>
  ${detailsEndHTML}`;

  return commentBody;
}

var iconSmallThread = `<svg width="24" height="24" class="crayons-icon" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M17 13l-5 6-5-6h3.125c0-3.314 2.798-6 6.25-6 .17 0 .34.006.506.02-1.787.904-3.006 2.705-3.006 4.78V13H17z" /></svg>`;

/**
 *
 * A function that triggers all the interactivity when a page with comments are loaded.
 * It calls sub-functions to define functionality for fetching async info, and attaching
 * event listeners related to rich UI interaction and form submission.
 *
 * When comment reaction data needs to be fetched and how we make those choices:
 * When no logged in user only need to fetch reaction numbers if there has been recent comment activity.
 * If no recent comments, we do not need the precision of fetching latest counts async. Static value is almost certainly good enough.
 * Always fetch when user is logged in because we need state of whether the user has reacted.
 *
 * @function initializeCommentsPage
 */
function initializeCommentsPage() {
  var commentableType;
  var commentsContainer = document.getElementById('comments-container');
  if (commentsContainer) {
    toggleCodeOfConduct();
    var userStatus = document.body.getAttribute('data-user-status');
    var commentableId = commentsContainer.dataset.commentableId;
    commentableType = commentsContainer.dataset.commentableType;
    var hasRecentCommentActivity =
      commentsContainer.dataset.hasRecentCommentActivity;
    var commentableIdList = (commentableId || '').split(',');

    if (userStatus === 'logged-in' || hasRecentCommentActivity !== 'false') {
      var pendingRequests = commentableIdList.length;
      if (pendingRequests === 0) {
        commentsContainer.dataset.commentsInitialized = 'true';
      }
      (function () {
        for (var i = 0; i < commentableIdList.length; i++) {
          (function (idx) {
            var ajaxReq = new XMLHttpRequest();
            ajaxReq.onreadystatechange = function () {
              if (ajaxReq.readyState === XMLHttpRequest.DONE) {
                try {
                  var responseObj = JSON.parse(ajaxReq.response);
                  var reactions = responseObj.reactions;
                  var allNodes = document.getElementsByClassName(
                    'single-comment-node',
                  );
                  var publicReactionCounts = responseObj.public_reaction_counts;
                  for (var j = 0; j < reactions.length; j++) {
                    var buttForComment = document.getElementById(
                      'button-for-comment-' + reactions[j].reactable_id,
                    );
                    if (buttForComment) {
                      buttForComment.classList.add('reacted');
                      buttForComment.setAttribute('aria-pressed', 'true');
                    }
                  }
                  for (var k = 0; k < publicReactionCounts.length; k++) {
                    var countButt = document.getElementById(
                      'button-for-comment-' + publicReactionCounts[k].id,
                    );
                    if (countButt) {
                      var reactionsCountWrapper =
                        countButt.querySelector('.reactions-count');
                      var reactionsLabelWrapper =
                        countButt.querySelector('.reactions-label');
                      if (
                        publicReactionCounts[k].count > 0 &&
                        reactionsLabelWrapper
                      ) {
                        if (publicReactionCounts[k].count > 1) {
                          reactionsLabelWrapper.innerHTML = `&nbsp;${I18n.t(
                            'core.like',
                          ).toLowerCase()}s`;
                        } else {
                          reactionsLabelWrapper.innerHTML = `&nbsp;${I18n.t(
                            'core.like',
                          ).toLowerCase()}`;
                        }

                        reactionsCountWrapper.id =
                          'reactions-count-' + publicReactionCounts[k].id;
                        reactionsCountWrapper.innerHTML =
                          publicReactionCounts[k].count;
                        reactionsCountWrapper.classList.remove('hidden');
                      } else {
                        reactionsCountWrapper.classList.add('hidden');
                        reactionsCountWrapper.innerHTML = '0';
                      }

                      if (!countButt.classList.contains('reacted')) {
                        countButt.setAttribute('aria-pressed', 'false');
                      }
                    }
                  }

                  for (var m = 0; m < allNodes.length; m++) {
                    if (
                      allNodes[m].dataset.commentAuthorId ==
                      responseObj.current_user.id
                    ) {
                      allNodes[m].dataset.currentUserComment = 'true';
                      var path = allNodes[m].dataset.path;
                      var userActionsEl = allNodes[m].querySelector(
                        '.current-user-actions',
                      );
                      var buttEl = document.getElementById(
                        'button-for-comment-' + allNodes[m].dataset.commentId,
                      );
                      if (userActionsEl && buttEl) {
                        userActionsEl.innerHTML = `<li><a href="${path}/edit" class="crayons-link crayons-link--block" aria-label="Edit this comment">Edit</a></li>
                                                  <li><a data-no-instant href="${path}/delete_confirm" class="edit-butt crayons-link crayons-link--block" aria-label="Delete this comment">Delete</a></li>`;
                        userActionsEl.classList.remove('hidden');
                      }
                    }
                  }
                } finally {
                  pendingRequests -= 1;
                  if (pendingRequests <= 0) {
                    commentsContainer.dataset.commentsInitialized = 'true';
                  }
                }
              }
            };

            ajaxReq.open(
              'GET',
              '/reactions?commentable_id=' +
                commentableIdList[idx] +
                '&commentable_type=' +
                commentableType,
              true,
            );
            ajaxReq.send();
          })(i);
        }
      })();
    } else {
      commentsContainer.dataset.commentsInitialized = 'true';
    }

    var butts = document.getElementsByClassName('reaction-button');
    for (var n = 0; n < butts.length; n++) {
      var butt = butts[n];
      butt.style.zIndex = butts.length - n;
      butt.onclick = function (event) {
        var thisButt = this;
        event.preventDefault();
        sendHapticMessage('medium');
        var currentStatus = document.body.getAttribute('data-user-status');
        if (currentStatus === 'logged-out') {
          showLoginModal({ referring_source: 'comment', trigger: 'like' });
          return;
        }

        thisButt.classList.add('reacted');
        thisButt.disabled = true;

        function successCb(response) {
          var reactionCount = thisButt.querySelector('.reactions-count');
          var reactionLabel = thisButt.querySelector('.reactions-label');
          if (response.result === 'create') {
            thisButt.classList.add('reacted');
            thisButt.setAttribute('aria-pressed', 'true');
            if (reactionCount) {
              reactionCount.innerHTML = parseInt(reactionCount.innerHTML) + 1;
              reactionCount.classList.remove('hidden');
              if (parseInt(reactionCount.innerHTML) == 1) {
                reactionLabel.innerHTML = '&nbsp;like';
              } else if (parseInt(reactionCount.innerHTML) > 1) {
                reactionLabel.innerHTML = '&nbsp;likes';
              }
            }
          } else {
            thisButt.classList.remove('reacted');
            thisButt.setAttribute('aria-pressed', 'false');
            if (reactionCount) {
              reactionCount.innerHTML = parseInt(reactionCount.innerHTML) - 1;
              if (parseInt(reactionCount.innerHTML) == 0) {
                reactionCount.classList.add('hidden');
                thisButt.classList.remove('crayons-btn--icon-left');
                thisButt.classList.add('crayons-btn--icon');
                reactionLabel.innerHTML = '';
              }
            }
          }
        }
        var formData = new FormData();
        formData.append('reactable_type', 'Comment');
        formData.append('reactable_id', thisButt.dataset.commentId);
        getCsrfToken()
          .then(sendFetch('reaction-creation', formData))
          .then(function (response) {
            thisButt.disabled = false;
            if (response.status === 200) {
              response.json().then(successCb);
            } else {
              showModalAfterError({
                response,
                element: 'reaction',
                action_ing: 'making',
                action_past: 'made',
              });
            }
          });
      };
    }
    var replyButts = document.getElementsByClassName('toggle-reply-form');
    for (var p = 0; p < replyButts.length; p++) {
      var replyButt = replyButts[p];
      replyButt.onclick = function (event) {
        event.preventDefault();
        if (event.target.classList.contains('thread-indication')) {
          return false;
        }
        var currentStatus = document.body.getAttribute('data-user-status');
        if (currentStatus == 'logged-out') {
          showLoginModal({ referring_source: 'comment', trigger: 'reply' });
          return;
        }
        var parentId = event.target.closest('.comment').dataset.commentId;
        var waitingOnCSRF = setInterval(function () {
          var metaTag = document.querySelector("meta[name='csrf-token']");
          if (metaTag) {
            clearInterval(waitingOnCSRF);
            var commentWrapper = event.target.closest('.comment__details');
            commentWrapper.classList.add('replying');
            commentWrapper.innerHTML += buildCommentFormHTML(
              commentableId,
              commentableType,
              parentId,
            );
            initializeCommentsPage();

            setTimeout(function () {
              var textarea = commentWrapper.getElementsByTagName('textarea')[0];
              if (textarea) {
                textarea.focus();
                if (
                  window.Forem &&
                  typeof window.Forem.initializeEnhancedCommentTextArea ===
                    'function'
                ) {
                  window.Forem.initializeEnhancedCommentTextArea(textarea);
                }
              }
            }, 30);
          }
        }, 1);
        return false;
      };
    }

    if (document.getElementById('new_comment')) {
      document
        .getElementById('new_comment')
        .addEventListener('submit', handleCommentSubmit);
    }
  }
  listenForDetailsToggle();

  handleHiddenComments(commentableType);
}

function toggleCodeOfConduct() {
  var user = userData();
  if (!user) {
    return;
  }
  var codeOfConduct = user.checked_code_of_conduct;
  var checkboxWrapper = document.getElementById(
    'toggle-code-of-conduct-checkbox',
  );
  if (checkboxWrapper && !codeOfConduct) {
    checkboxWrapper.innerHTML =
      '<input type="checkbox" name="checked_code_of_conduct" class="checkbox" required/>\
                                  <label for="checked_code_of_conduct">I\'ve read the <a href="/code-of-conduct">code of conduct</a></label>';
  }
}

function handleCommentSubmit(event) {
  event.preventDefault();
  var form = event.target;
  form.classList.add('submitting');
  var textarea = form.getElementsByClassName('comment-textarea')[0];
  if (textarea) {
    textarea.style.height = null;
    textarea.blur();
  }
  var parentComment = document.getElementById(
    'comment-node-' + event.target.dataset.commentId,
  );

  // as there can be multiple forms rendered in the comments, we need to use querySelector to find descendants
  var commentParentId = form.querySelector('#comment_parent_id');
  var body = JSON.stringify({
    comment: {
      body_markdown: form.getElementsByTagName('textarea')[0].value,
      commentable_id: form.querySelector('#comment_commentable_id').value,
      commentable_type: form.querySelector('#comment_commentable_type').value,
      parent_id: commentParentId ? commentParentId.value : null,
    },
  });

  getCsrfToken()
    .then(sendFetch('comment-creation', body))
    .then(function (response) {
      if (response.status === 200) {
        response.json().then(function (newComment) {
          var newNode = document.createElement('div');
          newNode.innerHTML = buildCommentHTML(newComment);
          var docBody = document.body;

          var parsedUserData = JSON.parse(docBody.getAttribute('data-user'));
          parsedUserData.checked_code_of_conduct = true;

          docBody.dataset.user = JSON.stringify(parsedUserData);

          var checkbox = form.getElementsByClassName('code-of-conduct')[0];
          if (checkbox) {
            checkbox.innerHTML = '';
          }

          var mainCommentsForm = document.getElementById('new_comment');
          if (parentComment) {
            handleFormClose(event, true);
            if (newComment.depth > 3) {
              var replyTrigger =
                parentComment.getElementsByClassName('toggle-reply-form')[0];
              var threadIndicator = `<span class="fs-s inline-flex items-center fs-italic color-base-50 pl-1">${iconSmallThread}Thread</span>`;
              replyTrigger.classList.replace('inline-flex', 'hidden');
              replyTrigger.parentNode.innerHTML += threadIndicator;
            }
            var actionsNode =
              parentComment.getElementsByClassName('comment__inner')[0];
            actionsNode.parentNode.insertBefore(
              newNode,
              actionsNode.nextSibling,
            );
          } else if (mainCommentsForm) {
            mainCommentsForm.classList.remove('submitting');
            mainCommentsForm.classList.remove('preview-open');

            const commentInputs = [
              ...form.getElementsByClassName('comment-textarea'),
            ];
            commentInputs[0]
              .closest('.comment-form')
              .classList.remove('comment-form--initiated');

            // Clearing out all comment textboxes and resetting their height because
            // there is an additional one generated by the comment
            // mention auto-complete component
            commentInputs.forEach((input) => {
              input.value = newComment.comment_template || '';
              input.style.height = null;
            });

            const preview = document.getElementById('preview-div');
            const togglePreview = document.querySelector('.preview-toggle');
            preview.innerHTML = '';
            togglePreview.innerHTML = 'Preview';
            const container = document.getElementById(
              'comment-trees-container',
            );
            container.insertBefore(newNode, container.firstChild);
          } else if (document.getElementById('notifications-container')) {
            var newDiv = document.createElement('span');
            newDiv.innerHTML =
              '<div class="crayons-notice align-center p-2 m-2 crayons-notice--success reply-sent-notice reply-sent-notice" aria-live="polite">Reply sent — <a href="' +
              newComment.url +
              '">Check it out</a></div>';
            form.replaceWith(newDiv);
          } else {
            window.location.replace(newComment.url);
          }
          updateCommentsCount();
          initializeCommentsPage();
          initializeCommentDate();
        });
      } else {
        form.classList.remove('submitting');
        showModalAfterError({
          response,
          element: 'comment',
          action_ing: 'posting',
          action_past: 'posted',
        });
        return false;
      }
      return false;
    });
  return false;
}

function handleFocus(event) {
  handleButtonsActivation(event);
  var userStatus = document.body.getAttribute('data-user-status');
  var area = event.target;
  if (userStatus == 'logged-out') {
    event.preventDefault();
    showLoginModal({ referring_source: 'comments', trigger: 'new_comment' });
    area.blur();
  } else {
    var form = event.target.closest('.comment-form');
    if (form) {
      form.classList.add('comment-form--initiated');
    }
    handleSizeChange(event);
    window.Forem.initializeEnhancedCommentTextArea(area);
  }
}

function handleKeyUp(event) {
  handleSizeChange(event);
  handleButtonsActivation(event);
}

// Handler for when Ctrl+Enter OR Command+Enter is pressed
function handleSubmit(event) {
  // Get user details and extract code of conduct & comment count
  var user = userData();
  if (!user) {
    return;
  }

  var codeOfConduct = user.checked_code_of_conduct;
  if (codeOfConduct && event.target.value.trim() !== '') {
    event.target.closest('form').querySelector('button[type="submit"]').click();
  }
}

var ENTER_KEY_CODE = 13;
function handleKeyDown(event) {
  if (
    window.Forem.Runtime.hasOSSpecificModifier(event) &&
    event.keyCode === ENTER_KEY_CODE
  ) {
    event.preventDefault();
    handleSubmit(event);
  }
}

function handleFormClose(event, forceClose) {
  // See if the classname exist
  const formEl = event.target.closest('.comment-form');
  if (!formEl) return;

  // Find the textarea inside this form
  const textarea = formEl.querySelector('textarea, .comment-form__textarea');
  const hasContent = textarea && textarea.value.trim().length > 0;

  // Only prompt if there is content in the reply area. This will prevent accidental deletion
  if (hasContent && !forceClose) {
    const ok = window.confirm(
      'Your comment will be erased. Are you sure you want to dismiss?',
    );
    if (!ok) {
      // User canceled dismissal
      return;
    }
  }

  // Remove the elements after confirmation from the user.
  const detailsEl = event.target.closest('.comment__details');

  if (detailsEl) {
    detailsEl.classList.remove('replying');
  }
  formEl.remove();
  initializeCommentsPage();
}

function handleSizeChange(event) {
  var textarea = event.target;
  var oldHeight = parseInt(textarea.style.height.replace('px', ''));
  textarea.style.height =
    textarea.scrollHeight + (textarea.scrollHeight > oldHeight ? 15 : 0) + 'px';
}

function handleButtonsActivation(event) {
  var textarea = event.target;
  var commentForm = textarea.closest('.comment-form');
  if (commentForm) {
    var buttons = commentForm.getElementsByClassName('js-btn-enable');
    Array.from(buttons).forEach(function (button) {
      button.disabled = textarea.value.length === 0;
    });
  }
}

function validateField(event) {
  // We only need to validate the textarea that is not the comment mention auto-complete component
  const textArea = event.target.form.querySelector(
    '.comment-textarea:not([role=combobox])',
  );

  if (textArea.value === '') {
    event.preventDefault();
  }
}

function handleChange(event) {
  handleButtonsActivation(event);
}

function generateUploadFormdata(image) {
  var token = document.querySelector("meta[name='csrf-token']").content;
  var formData = new FormData();
  formData.append('authenticity_token', token);
  formData.append('image', image[0]);
  return formData;
}

function updateItemSummaryHtml(item) {
  var itemSummaryContent = item.getElementsByClassName(
    'js-collapse-comment-content',
  )[0];
  var usernames = item.getElementsByClassName('js-comment-username');
  var number = '';
  if (usernames.length > 1) {
    number = ' + ' + (usernames.length - 1) + ' replies';
  }
  var itemUsername = usernames[0].textContent + number;
  if (item.open) {
    itemSummaryContent.textContent = '';
  } else {
    itemSummaryContent.textContent = itemUsername;
  }
}

function toggleCommentFromDepthIndicator(commentNode) {
  var wrapper = commentNode.parentElement;
  if (!wrapper || !wrapper.classList.contains('js-comment-wrapper')) {
    var depthMatch = commentNode.className.match(/comment--deep-(\d+)/);
    var depth = depthMatch ? parseInt(depthMatch[1], 10) : 3;
    var iconExpand =
      '<svg width="24" height="24" class="crayons-icon collapsed" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12 18L8 14.2287L8.99982 13.286L12 16.1147L15.0002 13.286L16 14.2287L12 18ZM12 7.88533L8.99982 10.714L8 9.77133L12 6L16 9.77133L15.0002 10.7133L12 7.88533Z" /></svg>';

    wrapper = document.createElement('details');
    wrapper.className =
      'comment-wrapper js-comment-wrapper comment-wrapper--deep-' +
      depth +
      ' child' +
      (depth > 3 ? ' comment-wrapper--too-deep' : '');
    wrapper.open = true;
    wrapper.innerHTML =
      '<summary aria-label="Toggle this comment (and replies)" data-tracking-name="expand_comment_toggle">' +
      '<span class="mx-0 inline-block align-middle">' +
      iconExpand +
      '</span>' +
      '<span class="js-collapse-comment-content inline-block align-middle"></span>' +
      '</summary>';

    commentNode.parentNode.insertBefore(wrapper, commentNode);
    wrapper.appendChild(commentNode);
    wrapper.addEventListener('toggle', function (e) {
      updateItemSummaryHtml(e.target);
    });
  }

  wrapper.open = !wrapper.open;
  updateItemSummaryHtml(wrapper);
}

function listenForDetailsToggle() {
  var detailItems = document.querySelectorAll('.js-comment-wrapper');
  for (var i = 0; i < detailItems.length; i++) {
    detailItems[i].addEventListener('toggle', (event) => {
      var item = event.target;
      updateItemSummaryHtml(item);
    });
  }

  var commentsContainer = document.getElementById('comments-container');
  if (commentsContainer && !commentsContainer.dataset.depthIndicatorBound) {
    commentsContainer.dataset.depthIndicatorBound = 'true';
    commentsContainer.addEventListener('click', function (event) {
      var target = event.target;
      if (!target || !target.classList) return;

      var inner = null;
      if (target.classList.contains('comment__inner')) {
        if (event.clientX < target.getBoundingClientRect().left) {
          inner = target;
        }
      } else if (
        target.classList.contains('comment') &&
        target.classList.contains('child')
      ) {
        var candidateInner = target.querySelector(':scope > .comment__inner');
        if (candidateInner) {
          var rect = candidateInner.getBoundingClientRect();
          if (
            event.clientX < rect.left &&
            event.clientY >= rect.top &&
            event.clientY <= rect.top + 48
          ) {
            inner = candidateInner;
          }
        }
      }

      if (inner) {
        var commentNode = inner.closest('.comment.child');
        if (commentNode) {
          event.preventDefault();
          toggleCommentFromDepthIndicator(commentNode);
        }
      }
    });
  }
}

/**
 * Increment comment, stored in `.js-comments-count`, count by one.
 */
function updateCommentsCount() {
  const commentsCountDiv = document.querySelector('.js-comments-count');

  // if there's nowhere to put the count return early.
  if (!commentsCountDiv) return;

  const commentsCountData =
    parseInt(commentsCountDiv.dataset.commentsCount, 10) + 1;
  commentsCountDiv.dataset.commentsCount = commentsCountData;
  commentsCountDiv.innerHTML = `(${commentsCountData})`;

  const commentsSidebarCountDiv = document.getElementById(
    'reaction-number-comment',
  );
  if (!commentsSidebarCountDiv) return;
  commentsSidebarCountDiv.innerHTML = `${commentsCountData}`;
}

function initializeCommentDate() {
  const commentsDates = document.querySelectorAll('.comment-date time');

  if (commentsDates) {
    addLocalizedDateTimeToElementsTitles(commentsDates, 'datetime');
  }
}

function handleHiddenComments(commentableType) {
  const currentUser = userData();
  const commentableAuthorIds = [];
  let coAuthorIds = '';
  if (commentableType === 'Article') {
    const articleContainer = document.querySelector('#article-show-container');
    if (articleContainer) {
      if (articleContainer.dataset) {
        commentableAuthorIds.push(articleContainer.dataset.authorId);
        coAuthorIds = articleContainer.dataset.coAuthorIds;
        if (coAuthorIds) {
          coAuthorIds.split(',').forEach((coAuthorId) => {
            commentableAuthorIds.push(coAuthorId);
          });
        }
      }
    } else {
      const commentsContainer = document.querySelector('#comments-container');
      if (commentsContainer && commentsContainer.dataset) {
        commentableAuthorIds.push(
          commentsContainer.dataset.commentableAuthorId,
        );
        coAuthorIds = commentsContainer.dataset.commentableCoAuthorIds;
        if (coAuthorIds) {
          coAuthorIds.split(',').forEach((coAuthorId) => {
            commentableAuthorIds.push(coAuthorId);
          });
        }
      }
    }
  } else if (commentableType === 'PodcastEpisode') {
    const podCastEpisodeContainer = document.querySelector(
      '.podcast-episode-container',
    );
    if (podCastEpisodeContainer) {
      commentableAuthorIds.push(podCastEpisodeContainer.dataset.creatorId);
    }
  }
  if (currentUser && commentableAuthorIds.includes(currentUser.id.toString())) {
    collapseCommentsHiddenByCommentableUser();
  } else {
    document
      .querySelectorAll('.element-hidden-by-commentable-user')
      .forEach((element) => {
        element.classList.add('hidden');
      });
    document
      .querySelectorAll('.comment-hidden-by-author-text')
      .forEach((element) => {
        element.classList.remove('hidden');
      });
  }
}

function collapseCommentsHiddenByCommentableUser() {
  document
    .querySelectorAll(
      '.js-comment-wrapper.details-comment-hidden-by-commentable-user',
    )
    .forEach((item) => {
      if (item.querySelectorAll('.comment-form').length === 0) {
        item.open = false;
        updateItemSummaryHtml(item);
      }
    });
}

window.__commentsPageBundleLoaded = true;

Object.assign(window, {
  buildCommentFormHTML,
  buildCommentHTML,
  reply,
  react,
  initializeCommentsPage,
  toggleCodeOfConduct,
  handleCommentSubmit,
  handleFocus,
  handleKeyUp,
  handleSubmit,
  handleKeyDown,
  handleFormClose,
  handleSizeChange,
  handleButtonsActivation,
  validateField,
  handleChange,
  generateUploadFormdata,
  updateItemSummaryHtml,
  toggleCommentFromDepthIndicator,
  listenForDetailsToggle,
  updateCommentsCount,
  initializeCommentDate,
  handleHiddenComments,
  collapseCommentsHiddenByCommentableUser,
});
