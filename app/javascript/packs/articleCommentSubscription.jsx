const userDataIntervalID = setInterval(async () => {
  const { user = null, userStatus } = document.body.dataset;

  if (userStatus === 'logged-out') {
    clearInterval(userDataIntervalID);
    return;
  }

  if (userStatus === 'logged-in' && user !== null) {
    // only load the comment subscription button for logged on users.
    clearInterval(userDataIntervalID);

    try {
      const { loadCommentSubscription } = await import(
        '../CommentSubscription/commentSubscriptionUtilities'
      );

      const { articleId } = document.querySelector('#article-body').dataset;
      loadCommentSubscription(articleId);
    } catch (e) {
      document.querySelector('#comment-subscription').innerHTML =
        '<p style="color: rgb(220, 24, 24);">Unable to load Comment Subscription component.<br />Try refreshing the page.</p>';
    }
  }
});
