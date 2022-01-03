/* global userData */
import { isModerationPage } from '@utilities/moderation';

getCsrfToken().then(() => {
  const user = userData();
  const { authorId: articleAuthorId, path } = document.getElementById(
    'article-show-container',
  ).dataset;

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
        // dev.to/mod
      } else if (isModerationPage()) {
        initializeActionsPanel(user, path);
        initializeFlagUserModal(articleAuthorId);
      }
    }
  };

  initializeModerationsTools();
});
