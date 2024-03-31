// subscribeButton.test.js

import {
  initializeSubscribeButton,
  updateSubscribeButtonText,
  determinePayloadAndEndpoint,
} from '../../subscribeButton';

describe('subscribeButton', () => {
  let button;
  let originalFetch;

  beforeEach(() => {
    button = document.createElement('button');
    button.classList.add('subscribe-button');
    document.body.appendChild(button);
    const spanElement = document.createElement('span');
    spanElement.textContent = 'Subscribe to comments';
    button.appendChild(spanElement);

    // Baseline scenario starts Subscribed to all comments on an article
    button.setAttribute('data-subscription_id', '1');
    button.setAttribute('data-subscribed_to', 'article');
    button.setAttribute('data-subscription_mode', 'all_comments');
    button.setAttribute('data-article_id', '123');

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

  it('should update to unsubscribed setting label, and *not* pressed', () => {
    updateSubscribeButtonText(button, 'unsubscribe');

    expect(button.getAttribute('aria-label')).toBe('Subscribe to comments');
    expect(button.querySelector('span').innerText).toBe(
      'Subscribe to comments',
    );
    expect(button.getAttribute('aria-pressed')).toBe('false');
  });

  it('should update without override with blank subscription_id setting label, and *not* pressed', () => {
    button.setAttribute('data-subscription_id', '');

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
    expect(button.querySelector('span').innerText).toBe('Subscribed to thread');
    expect(button.getAttribute('aria-pressed')).toBe('true');
  });

  it('was-subscribed-to-thread scenario', () => {
    button.setAttribute('data-subscription_id', '');
    button.setAttribute('data-subscription_config', 'thread');
    button.setAttribute('data-subscribed_to', 'comment');
    button.setAttribute('data-comment_id', '456');
    updateSubscribeButtonText(button, 'unsubscribe');

    expect(button.getAttribute('aria-label')).toBe('Subscribe to thread');
    expect(button.querySelector('span').innerText).toBe('Subscribe to thread');
    expect(button.getAttribute('aria-pressed')).toBe('false');
  });

  it('should capitalize the mobileLabel', () => {
    const magicalWindowSize = 700;
    updateSubscribeButtonText(button, 'subscribe', magicalWindowSize);

    expect(button.getAttribute('aria-label')).toBe('Subscribed to comments');
    expect(button.querySelector('span').innerText).toBe('Comments');

    updateSubscribeButtonText(button, 'unsubscribe', magicalWindowSize);
    expect(button.getAttribute('aria-label')).toBe('Subscribe to comments');
    expect(button.querySelector('span').innerText).toBe('Comments');

    button.setAttribute('data-subscription_config', 'top_level_comments');
    updateSubscribeButtonText(button, 'subscribe', magicalWindowSize);
    expect(button.getAttribute('aria-label')).toBe(
      'Subscribed to top-level comments',
    );
    expect(button.querySelector('span').innerText).toBe('Top-level comments');

    button.setAttribute('data-subscription_config', 'only_author_comments');
    updateSubscribeButtonText(button, 'subscribe', magicalWindowSize);
    expect(button.getAttribute('aria-label')).toBe(
      'Subscribed to author comments',
    );
    expect(button.querySelector('span').innerText).toBe('Author comments');

    button.setAttribute('data-subscription_config', 'unknown_config');
    updateSubscribeButtonText(button, 'subscribe', magicalWindowSize);
    expect(button.getAttribute('aria-label')).toBe('Subscribed to comments');
    expect(button.querySelector('span').innerText).toBe('Comments');
  });

  it('should determine the expected payload', async () => {
    let { payload, endpoint } = determinePayloadAndEndpoint(button);

    // Baseline case: **is** subscribed
    expect(payload).toEqual({ subscription_id: '1' });
    expect(endpoint).toEqual('comment-unsubscribe');

    // When unsubscribed from an article
    button.setAttribute('data-subscription_id', '');
    ({ payload, endpoint } = determinePayloadAndEndpoint(button));
    expect(payload).toEqual({ article_id: '123' });
    expect(endpoint).toEqual('comment-subscribe');

    // When unsubscribed from a thread
    button.setAttribute('data-subscription_id', '');
    button.setAttribute('data-subscription_config', 'thread');
    button.setAttribute('data-subscribed_to', 'comment');
    button.setAttribute('data-comment_id', '456');
    ({ payload, endpoint } = determinePayloadAndEndpoint(button));
    expect(payload).toEqual({ comment_id: '456' });
    expect(endpoint).toEqual('comment-subscribe');
  });
});
