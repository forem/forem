import {
  WINDOW_MODAL_ID,
  loadWindowModalBundle,
  resetWindowModalLoaderForTests,
} from '../windowModalLoader';
import { showWindowModal, closeWindowModal } from '../showModal';

describe('windowModalLoader and showModal', () => {
  beforeEach(() => {
    resetWindowModalLoaderForTests();
    document.head.innerHTML = '';
    document.body.innerHTML = '';
    delete window.Forem;
  });

  it('resolves immediately when window.Forem.renderWindowModal is already registered', async () => {
    const mockRender = jest.fn();
    const mockUnmount = jest.fn();
    window.Forem = {
      renderWindowModal: mockRender,
      unmountWindowModal: mockUnmount,
    };

    const result = await loadWindowModalBundle();
    expect(result).toEqual({
      renderWindowModal: mockRender,
      unmountWindowModal: mockUnmount,
    });
  });

  it('loads the script from the window-modal-script meta tag and delegates showWindowModal', async () => {
    const meta = document.createElement('meta');
    meta.name = 'window-modal-script';
    meta.content = '/assets/windowModal-test123.js';
    document.head.appendChild(meta);

    const mockRender = jest.fn();
    const promise = showWindowModal({ title: 'Hello', modalContent: '<p>Hi</p>' });

    const script = document.querySelector(
      'script[src="/assets/windowModal-test123.js"]',
    );
    expect(script).not.toBeNull();

    window.Forem = {
      renderWindowModal: mockRender,
      unmountWindowModal: jest.fn(),
    };
    script.dispatchEvent(new Event('load'));

    await promise;
    expect(mockRender).toHaveBeenCalledWith({
      title: 'Hello',
      modalContent: '<p>Hi</p>',
    });
  });

  it('does not load the bundle in closeWindowModal when no modal container exists', async () => {
    await closeWindowModal(document);
    expect(
      document.querySelector('script[data-window-modal-bundle="true"]'),
    ).toBeNull();
  });

  it('unmounts when closeWindowModal is called and the modal container exists', async () => {
    const container = document.createElement('div');
    container.id = WINDOW_MODAL_ID;
    document.body.appendChild(container);

    const mockUnmount = jest.fn();
    window.Forem = {
      renderWindowModal: jest.fn(),
      unmountWindowModal: mockUnmount,
    };

    await closeWindowModal(document);
    expect(mockUnmount).toHaveBeenCalledWith(document);
  });

  it('cleans up the failed script tag on error so subsequent calls can retry', async () => {
    const firstAttempt = loadWindowModalBundle();
    const firstScript = document.querySelector(
      'script[data-window-modal-bundle="true"]',
    );
    expect(firstScript).not.toBeNull();

    firstScript.dispatchEvent(new Event('error'));
    await expect(firstAttempt).rejects.toThrow('Failed to load');
    expect(
      document.querySelector('script[data-window-modal-bundle="true"]'),
    ).toBeNull();
  });
});
