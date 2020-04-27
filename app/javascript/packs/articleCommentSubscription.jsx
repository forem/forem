const userDataIntervalID = setInterval(async () => {
  const { user = null, userStatus } = document.body.dataset;

  if (userStatus === 'logged-out') {
    clearInterval(userDataIntervalID);
    return;
  }

  if (userStatus === 'logged-in' && user !== null) {
    // only load the comment subscription button for logged on users.
    clearInterval(userDataIntervalID);
    const { loadCommentSubscription } = await import(
      '../CommentSubscription/commentSubscriptionUtilities'
    );

    loadCommentSubscription();
  }
});
