/* global userData */
import { isModerationPage } from '@utilities/moderation';

getCsrfToken().then(() => {
  const articleContainer = document.getElementById('article-show-container');

  if (articleContainer) {
    const user = userData();
    const { authorId: articleAuthorId, path } = articleContainer.dataset;

    const initializeModerationsTools = async () => {
      const { initializeActionsPanel } = await import(
        '../actionsPanel/initializeActionsPanelToggle'
      );
      const { initializeFlagUserModal } = await import('./flagUserModal');

      // If the user can moderate an article give them access to this panel.
      // Note: this assumes we're within the article context (which is the case
      // given the articleContainer)
      const canModerateArticles = user?.policies?.find(
        (o) =>
          o.dom_class === 'js-policy-article-moderate' && o.visible === true,
      );

      // article show page
      if (canModerateArticles) {
        if (
          parseInt(user?.id) !== parseInt(articleAuthorId) &&
          !isModerationPage()
        ) {
          initializeActionsPanel(user, path);
          initializeFlagUserModal(articleAuthorId);
          // "/mod" page
        } else if (isModerationPage()) {
          initializeActionsPanel(user, path);
          initializeFlagUserModal(articleAuthorId);
        }
      }
    };

    initializeModerationsTools();
  }
});
