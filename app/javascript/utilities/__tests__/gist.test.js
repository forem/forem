import {
  embedGists,
  loadPostScribe,
  resetPostscribeLoaderForTests,
} from '../gist';

describe('gist utility and postscribeLoader', () => {
  beforeEach(() => {
    resetPostscribeLoaderForTests();
    document.head.innerHTML = '';
    document.body.innerHTML = '';
    delete window.Forem;
    global.InstantClick = {
      on: jest.fn(),
    };
  });

  it('does not fetch postscribe when no .ltag_gist-liquid-tag elements exist', async () => {
    const container = document.createElement('div');
    document.body.appendChild(container);

    await embedGists(container);

    expect(
      document.querySelector('script[data-postscribe-bundle="true"]'),
    ).toBeNull();
  });

  it('loads postscribe and renders gist tags when .ltag_gist-liquid-tag elements exist', async () => {
    const mockPostscribe = jest.fn();
    window.Forem = { postscribe: mockPostscribe };

    const container = document.createElement('div');
    const gistTag = document.createElement('div');
    gistTag.className = 'ltag_gist-liquid-tag';
    const wrapper = document.createElement('div');
    wrapper.innerHTML = '<script src="https://gist.github.com/example.js"></script>';
    gistTag.appendChild(wrapper);
    container.appendChild(gistTag);
    document.body.appendChild(container);

    await embedGists(container);

    expect(mockPostscribe).toHaveBeenCalledTimes(1);
    expect(gistTag.contains(wrapper)).toBe(false);
  });

  it('loads the postscribeLoader script from the meta tag when not yet on window.Forem', async () => {
    const meta = document.createElement('meta');
    meta.name = 'postscribe-script';
    meta.content = '/assets/postscribeLoader-test.js';
    document.head.appendChild(meta);

    const mockPostscribe = jest.fn();
    const promise = loadPostScribe();

    const script = document.querySelector(
      'script[src="/assets/postscribeLoader-test.js"]',
    );
    expect(script).not.toBeNull();

    window.Forem = { postscribe: mockPostscribe };
    script.dispatchEvent(new Event('load'));

    await expect(promise).resolves.toBe(mockPostscribe);
  });
});
