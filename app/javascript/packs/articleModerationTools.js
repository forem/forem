/* eslint-disable no-restricted-globals */
/* eslint-disable no-undef */
const user = userData();
const { authorId: articleAuthorId, path } = document.getElementById(
  'article-show-container',
).dataset;

const initializeModerationsTools = async () => {
  const { default: initializeActionsPanel } = await import(
    '../actionsPanel/initializeActionsPanelToggle'
  );

  // article show page
  if (
    user.trusted &&
    user.id !== articleAuthorId &&
    !top.document.location.pathname.endsWith('/mod')
  ) {
    initializeActionsPanel(user, path);
    // dev.to/mod
  } else if (user.trusted && top.document.location.pathname.endsWith('/mod')) {
    initializeActionsPanel(user, path);
  }
};

initializeModerationsTools();
/* eslint-enable no-restricted-globals */
/* eslint-enable no-undef */
