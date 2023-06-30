// subscribeButton.test.js

import {
  initializeSubscribeButton,
  updateSubscribeButtonText,
  optimisticallyUpdateButtonUI,
} from '../../subscribeButton';

describe('subscribeButton', () => {
  let button;
  let originalFetch;
  const mockDatasetComment = (comment) => {
    button.dataset.comment = comment;
  };

  beforeEach(() => {
    button = document.createElement('button');
    button.classList.add('subscribe-button');
    document.body.appendChild(button);
    const spanElement = document.createElement('span');
    spanElement.textContent = 'Subscribe to comments';
    button.appendChild(spanElement);

    // Baseline scenario starts Subscribed to all comments on an article
    button.setAttribute('data-subscription_id','1');
    button.setAttribute('data-subscribed_to','article');
    button.setAttribute('data-subscription_mode','all_comments');
    button.setAttribute('data-article_id','123');

    // Store the original fetch function
    originalFetch = global.fetch;

    // Mock the fetch function with a spy
    global.fetch = jest.fn().mockImplementation(() => Promise.resolve({}));

    initializeSubscribeButton();
  });

  afterEach(() => {
    document.body.removeChild(button);

    // Restore the original fetch function
    global.fetch = originalFetch;
  });

  it('should initialize subscribe buttons', () => {
    expect(button.getAttribute('aria-label')).toBe('Subscribed to comments');
    expect(button.querySelector('span').innerText).toBe(
      'Subscribed to comments',
    );
  });

  it('should update to unsubscribed setting label, mobileLabel, and *not* pressed', () => {
    updateSubscribeButtonText(button, "unsubscribe");

    expect(button.getAttribute('aria-label')).toBe('Subscribe to comments');
    expect(button.querySelector('span').innerText).toBe(
      'Subscribe to comments',
    );
    expect(button.getAttribute('aria-pressed')).toBe('false');
  });

  it('should update without override with blank subscription_id setting label, mobileLabel, and *not* pressed', () => {
    button.setAttribute('data-subscription_id','');

    updateSubscribeButtonText(button);

    expect(button.getAttribute('aria-label')).toBe('Subscribe to comments');
    expect(button.querySelector('span').innerText).toBe(
      'Subscribe to comments',
    );
    expect(button.getAttribute('aria-pressed')).toBe('false');
  });

  it('"top_level_comments" scenario', () => {
    button.setAttribute('data-subscription_config', 'top_level_comments');
    updateSubscribeButtonText(button);

    expect(button.getAttribute('aria-label')).toBe(
      'Subscribed to top-level comments',
    );
    expect(button.querySelector('span').innerText).toBe(
      'Subscribed to top-level comments',
    );
    expect(button.getAttribute('aria-pressed')).toBe('true');
  });

  it('"only_author_comments" scenario', () => {
    button.setAttribute('data-subscription_config', 'only_author_comments');
    updateSubscribeButtonText(button);

    expect(button.getAttribute('aria-label')).toBe(
      'Subscribed to author comments',
    );
    expect(button.querySelector('span').innerText).toBe(
      'Subscribed to author comments',
    );
    expect(button.getAttribute('aria-pressed')).toBe('true');
  });

  it('unknown config scenario', () => {
    button.setAttribute('data-subscription_config', 'unknown_config');
    updateSubscribeButtonText(button);

    expect(button.getAttribute('aria-label')).toBe('Subscribed to comments');
    expect(button.querySelector('span').innerText).toBe(
      'Subscribed to comments',
    );
    expect(button.getAttribute('aria-pressed')).toBe('true');
  });

  it('subscribed-to-thread scenario', () => {
    button.setAttribute('data-subscription_config', 'thread');
    button.setAttribute('data-subscribed_to', 'comment');
    button.setAttribute('data-comment_id', '456');
    updateSubscribeButtonText(button);

    expect(button.getAttribute('aria-label')).toBe('Subscribed to thread');
    expect(button.querySelector('span').innerText).toBe(
      'Subscribed to thread',
    );
    expect(button.getAttribute('aria-pressed')).toBe('true');
  });

  it('was-subscribed-to-thread scenario', () => {
    button.setAttribute('data-subscription_id','');
    button.setAttribute('data-subscription_config', 'thread');
    button.setAttribute('data-subscribed_to', 'comment');
    button.setAttribute('data-comment_id', '456');
    updateSubscribeButtonText(button, 'unsubscribe');

    expect(button.getAttribute('aria-label')).toBe('Subscribe to thread');
    expect(button.querySelector('span').innerText).toBe(
      'Subscribe to thread',
    );
    expect(button.getAttribute('aria-pressed')).toBe('false');
  });

  it('should capitalize the mobileLabel', () => {
    mockDatasetComment('some comment');
    updateSubscribeButtonText(button, 'all_comments');

    expect(button.getAttribute('aria-label')).toBe('Subscribed to comments');
    expect(button.querySelector('span').innerText).toBe(
      'Subscribed to comments',
    );
    expect(button.getAttribute('aria-pressed')).toBe('true');
  });

  // it('should remove "comment-subscribed" class and set inner text for known configs', () => {
  //   optimisticallyUpdateButtonUI(button);
  //
  //   expect(button.classList.contains('comment-subscribed')).toBe(false);
  //   expect(button.querySelector('span').innerText).toBe(
  //     'Subscribe to comments',
  //   );
  // });

  // it('should add "comment-subscribed" class and call updateSubscribeButtonText for unknown config', () => {
  //   optimisticallyUpdateButtonUI(button);
  //
  //   expect(button.classList.contains('comment-subscribed')).toBe(false);
  //   expect(button.querySelector('span').innerText).toBe(
  //     'Subscribe to comments',
  //   );
  //   expect(button.getAttribute('aria-label')).toBe('Subscribe to comments');
  //   expect(button.getAttribute('aria-pressed')).toBe('false');
  // });

  it('should add "comment-subscribed" class and call updateSubscribeButtonText when buttonInfo is null', () => {
    delete button.dataset.info;
    optimisticallyUpdateButtonUI(button);

    expect(button.classList.contains('comment-subscribed')).toBe(true);
    expect(button.querySelector('span').innerText).toBe(
      'Subscribed to comments',
    );
    expect(button.getAttribute('aria-label')).toBe('Subscribed to comments');
    expect(button.getAttribute('aria-pressed')).toBe('true');
  });
});
