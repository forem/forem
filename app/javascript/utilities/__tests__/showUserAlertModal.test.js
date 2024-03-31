import 'isomorphic-fetch';
import {
  getModalHtml,
  showModalAfterError,
} from '../../utilities/showUserAlertModal';

describe('ShowUserAlert Utility', () => {
  beforeEach(() => {
    const mockShowModal = jest.fn();
    global.window.Forem = { showModal: mockShowModal };
  });

  it('should return modal html', () => {
    const modalHtml = getModalHtml('Sample text', 'Sample Confirm Text');
    expect(modalHtml).toContain('Sample text');
  });

  test('shows rate limit modal if response status is 429', async () => {
    const response = new Response('', { status: 429 });
    const showRateLimitModal = jest.fn();
    const showUserAlertModal = jest.fn();

    await showModalAfterError({
      response,
      element: 'post',
      action_ing: 'creating',
      action_past: 'created',
      timeframe: '5 minutes',
      showRateLimitModal,
      showUserAlertModal,
    });

    expect(showUserAlertModal).not.toHaveBeenCalled();
  });

  test('shows user alert modal if response status is not 429', async () => {
    const response = new Response(
      JSON.stringify({ error: 'Something went wrong' }),
    );
    const showRateLimitModal = jest.fn();
    const showUserAlertModal = jest.fn();

    await showModalAfterError({
      response,
      element: 'post',
      action_ing: 'creating',
      action_past: 'created',
      timeframe: '5 minutes',
      showRateLimitModal,
      showUserAlertModal,
    });

    expect(showRateLimitModal).not.toHaveBeenCalled();
  });

  test('shows user alert modal if response cannot be parsed as JSON', async () => {
    const response = new Response('Something went wrong', { status: 500 });
    const showRateLimitModal = jest.fn();
    const showUserAlertModal = jest.fn();

    await showModalAfterError({
      response,
      element: 'post',
      action_ing: 'creating',
      action_past: 'created',
      timeframe: '5 minutes',
      showRateLimitModal,
      showUserAlertModal,
    });

    expect(showRateLimitModal).not.toHaveBeenCalled();
  });
});
