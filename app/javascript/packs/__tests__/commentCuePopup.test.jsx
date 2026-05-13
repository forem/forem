import { init } from '../commentCuePopup';

function buildPage({ flag = 'comment_cue_popup', message = 'Jump in!' } = {}) {
  document.body.innerHTML = `
    <div id="article-wrapper">
      <div id="article-body"
           data-article-id="42"
           data-cue-message="${message}"
           data-cue-close-label="Dismiss"></div>
    </div>
  `;
  document.body.dataset.globalFeatureFlagsEnabled = flag;
}

describe('comment cue init', () => {
  let observerSpy;
  let observeMock;
  let disconnectMock;

  beforeEach(() => {
    document.body.innerHTML = '';
    delete document.body.dataset.globalFeatureFlagsEnabled;
    sessionStorage.clear();
    observeMock = jest.fn();
    disconnectMock = jest.fn();
    observerSpy = jest.fn(function MockIO(callback) {
      this.callback = callback;
      this.observe = observeMock;
      this.disconnect = disconnectMock;
    });
    global.IntersectionObserver = observerSpy;
  });

  it('does nothing when the global flag is absent', () => {
    buildPage({ flag: 'something_else' });
    init();
    expect(observerSpy).not.toHaveBeenCalled();
  });

  it('does nothing when the article was already dismissed in this session', () => {
    buildPage();
    sessionStorage.setItem('commentCueDismissed:42', '1');
    init();
    expect(observerSpy).not.toHaveBeenCalled();
  });

  it('does nothing when the article body is missing', () => {
    document.body.dataset.globalFeatureFlagsEnabled = 'comment_cue_popup';
    init();
    expect(observerSpy).not.toHaveBeenCalled();
  });

  it('does nothing when no message is provided', () => {
    buildPage({ message: '' });
    init();
    expect(observerSpy).not.toHaveBeenCalled();
  });

  it('appends a sentinel to the article wrapper and observes it', () => {
    buildPage();
    init();
    expect(observerSpy).toHaveBeenCalledTimes(1);
    const wrapper = document.getElementById('article-wrapper');
    const sentinel = wrapper.querySelector('.comment-cue-sentinel');
    expect(sentinel).not.toBeNull();
    expect(sentinel.parentElement).toBe(wrapper);
    expect(wrapper.lastElementChild).toBe(sentinel);
    expect(observeMock).toHaveBeenCalledWith(sentinel);
  });
});
