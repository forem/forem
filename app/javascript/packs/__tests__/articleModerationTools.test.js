import '@testing-library/jest-dom';

jest.mock('../../actionsPanel/initializeActionsPanelToggle', () => ({
  initializeActionsPanel: jest.fn(),
}));

describe('articleModerationTools pack', () => {
  beforeEach(() => {
    jest.resetModules();
    document.body.innerHTML = '<div id="index-container"></div>';
    global.getCsrfToken = jest.fn(() => Promise.resolve('csrf-token'));
    global.userData = jest.fn(() => ({
      id: 123,
      policies: [
        {
          dom_class: 'js-policy-article-moderate',
          visible: true,
        },
      ],
    }));
  });

  afterEach(() => {
    delete global.getCsrfToken;
    delete global.userData;
  });

  it('initializes moderation tools when a feed container exists', async () => {
    const { initializeActionsPanel } = await import(
      '../../actionsPanel/initializeActionsPanelToggle'
    );

    await import('../articleModerationTools');
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(initializeActionsPanel).toHaveBeenCalledTimes(1);
  });
});
