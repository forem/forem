/* global userData */
import { isModerationPage } from '@utilities/moderation';

getCsrfToken().then(() => {
  const articleContainer = document.getElementById('article-show-container');
  const feedContainer = document.getElementById('index-container') || document.getElementById('homepage-feed');
  const hasModerationButtons = document.getElementsByClassName(
    'mod-actions-menu-btn',
  ).length;

  if (articleContainer || feedContainer || hasModerationButtons) {
    const user = userData();
    const { authorId: articleAuthorId, path } = articleContainer?.dataset || {};

    const initializeModerationsTools = async () => {
      const { initializeActionsPanel } = await import(
        '../actionsPanel/initializeActionsPanelToggle'
      );

      // If the user can moderate an article give them access to this panel.
      const canModerateArticles = user?.policies?.find(
        (o) =>
          o.dom_class === 'js-policy-article-moderate' && o.visible === true,
      );

      if (canModerateArticles) {
        // <2022-05-09 Mon> [@jeremyf] the user.id is an integer and
        // articleAuthorId is a string so our logic is such that we always
        // initializeActionsPanel and initializeFlagUserModal; I'm asking
        // product to clarify if we want mods to boost their own posts.
        if (articleContainer && user?.id !== articleAuthorId && !isModerationPage()) {
          initializeActionsPanel(user, path);
          // "/mod" page or feed cards
        } else if (isModerationPage() || !articleContainer) {
          initializeActionsPanel(user, path);
        }
      }
    };

    initializeModerationsTools();
  }
});
