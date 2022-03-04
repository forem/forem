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

      // article show page
      if (user?.trusted) {
        if (user?.id !== articleAuthorId && !isModerationPage()) {
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
