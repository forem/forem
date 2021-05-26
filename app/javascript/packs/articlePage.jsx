import { h, render } from 'preact';
import { Snackbar, addSnackbarItem } from '../Snackbar';
import { addFullScreenModeControl } from '../utilities/codeFullscreenModeSwitcher';
import { initializeDropdown } from '@utilities/dropdownUtils';

const fullscreenActionElements = document.getElementsByClassName(
  'js-fullscreen-code-action',
);

if (fullscreenActionElements) {
  addFullScreenModeControl(fullscreenActionElements);
}

// The Snackbar for the article page
const snackZone = document.getElementById('snack-zone');

if (snackZone) {
  render(<Snackbar lifespan="3" />, snackZone);
}

// eslint-disable-next-line no-restricted-globals
top.addSnackbarItem = addSnackbarItem;

// Initialize the share options
const shareDropdownButton = document.getElementById('article-show-more-button');
const shareDropdownContent = document.getElementById(
  'article-show-more-dropdown',
);
// TODO: There was other code in the initializer around android share, but Fernando's PR changes this

if (shareDropdownButton.dataset.initialized !== 'true') {
  const { closeDropdown } = initializeDropdown({
    triggerButtonElementId: 'article-show-more-button',
    dropdownContentElementId: 'article-show-more-dropdown',
  });
  // In addition to standard dropdown actions, we also want to close on link select (since they open in a new tab)
  const allLinks = shareDropdownContent.querySelectorAll('[href');
  allLinks.forEach((link) => link.addEventListener('click', closeDropdown));

  shareDropdownButton.dataset.initialized = 'true';
}

const userDataIntervalID = setInterval(async () => {
  const { user = null, userStatus } = document.body.dataset;

  clearInterval(userDataIntervalID);
  const root = document.getElementById('comment-subscription');
  const isLoggedIn = userStatus === 'logged-in';

  try {
    const {
      getCommentSubscriptionStatus,
      setCommentSubscriptionStatus,
      CommentSubscription,
    } = await import('../CommentSubscription');

    const { articleId } = document.getElementById('article-body').dataset;

    let subscriptionType = 'not_subscribed';

    if (isLoggedIn && user !== null) {
      ({ config: subscriptionType } = await getCommentSubscriptionStatus(
        articleId,
      ));
    }

    const subscriptionRequestHandler = async (type) => {
      const message = await setCommentSubscriptionStatus(articleId, type);

      addSnackbarItem({ message, addCloseButton: true });
    };

    render(
      <CommentSubscription
        subscriptionType={subscriptionType}
        positionType="static"
        onSubscribe={subscriptionRequestHandler}
        onUnsubscribe={subscriptionRequestHandler}
        isLoggedIn={isLoggedIn}
      />,
      root,
    );
  } catch (e) {
    document.getElementById('comment-subscription').innerHTML =
      '<p className="color-accent-danger">Unable to load Comment Subscription component.<br />Try refreshing the page.</p>';
  }
});
