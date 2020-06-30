import { h, render } from 'preact';
import { Snackbar, addSnackbarItem } from '../Snackbar';

// The Snackbar for the article page
const snackZone = document.getElementById('snack-zone');

if (snackZone) {
  render(<Snackbar lifespan="3" />, snackZone);
}

// eslint-disable-next-line no-restricted-globals
top.addSnackbarItem = addSnackbarItem;

const userDataIntervalID = setInterval(async () => {
  const { user = null, userStatus } = document.body.dataset;

  if (userStatus === 'logged-out') {
    // User is not logged on so nothing dynamic to add to the page.
    clearInterval(userDataIntervalID);
    return;
  }

  // Somewhat works. Not elegent or fully functional.
  const codeBlocks = document.querySelectorAll('div.highlight');

  codeBlocks.forEach(block => {
    block.insertAdjacentHTML('beforeend', '<button class="crayons-btn crayons-btn--secondary crayons-btn--icon crayons-btn--s pt-0"><svg data-content="fullscreen" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="15" height="15"><path data-content="fullscreen" fill="none" d="M0 0h24v24H0z"></path><path data-content="fullscreen" d="M20 3h2v6h-2V5h-4V3h4zM4 3h4v2H4v4H2V3h2zm16 16v-4h2v6h-6v-2h4zM4 19h4v2H2v-6h2v4z"></path></svg></button>');
    block.querySelector('button').onclick = (e) => {
      document.body.classList.toggle('modal-open');
      if (document.body.classList.contains('modal-open')) {
        block.classList.add('crayons-fullscreen');
        block.insertAdjacentHTML('beforeBegin', '<div class="crayons-fullscreenbg"></div>');
      } else {
        block.classList.remove('crayons-fullscreen');
        //crayons-fullscreenbg is just a random placeholder.
        document.querySelector('.crayons-fullscreenbg').style.display = 'none';
      }
    }
  });
  
  if (userStatus === 'logged-in' && user !== null) {
    // Load the comment subscription button for logged on users.
    clearInterval(userDataIntervalID);
    const root = document.querySelector('#comment-subscription');

    try {
      const {
        getCommentSubscriptionStatus,
        setCommentSubscriptionStatus,
        CommentSubscription,
      } = await import('../CommentSubscription');

      const { articleId } = document.querySelector('#article-body').dataset;
      const { config: subscriptionType } = await getCommentSubscriptionStatus(
        articleId,
      );
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
        />,
        root,
      );
    } catch (e) {
      document.querySelector('#comment-subscription').innerHTML =
        '<p className="color-accent-danger">Unable to load Comment Subscription component.<br />Try refreshing the page.</p>';
    }
  }
});
