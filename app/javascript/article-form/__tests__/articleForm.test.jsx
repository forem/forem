import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow, deep } from 'preact-render-spy';
import { JSDOM } from 'jsdom';
import ArticleForm from '../articleForm';
import algoliasearch from '../elements/__mocks__/algoliasearch';

const dummyArticleUpdatedAt = new Date();
const getArticleForm = () => (
  <ArticleForm
    version="v2"
    article={`{ "id": null, "body_markdown": null, "cached_tag_list": null, "main_image": null, "published": false, "title": null, "updated_at": "${dummyArticleUpdatedAt}"}`}
  />
);

describe('<ArticleForm />', () => {
  beforeEach(() => {
    const doc = new JSDOM('<!doctype html><html><body></body></html>');
    global.document = doc;
    global.window = doc.defaultView;

    global.document.body.createTextRange = function createTextRange() {
      return {
        setEnd() {},
        setStart() {},
        getBoundingClientRect() {
          return { right: 0 };
        },
        getClientRects() {
          return {
            length: 0,
            left: 0,
            right: 0,
          };
        },
      };
    };

    global.document.body.innerHTML = "<div id='editor-help-guide'></div>";

    global.window.algoliasearch = algoliasearch;

    localStorage.clear();
    /* eslint-disable-next-line no-underscore-dangle */
    localStorage.__STORE__ = {};
  });

  it('renders properly', () => {
    const tree = render(getArticleForm());
    expect(tree).toMatchSnapshot();
  });

  it('initally loads blank', () => {
    const form = shallow(getArticleForm());
    expect(form.state().bodyMarkdown).toBe('');
  });

  it('loads text from sessionstorage when available', () => {
    localStorage.setItem(
      'editor-v2-http://localhost/',
      JSON.stringify({ bodyMarkdown: 'hello, world', updatedAt: new Date() }),
    );
    const form = shallow(getArticleForm());
    expect(form.state().bodyMarkdown).toBe('hello, world');
  });

  it('do not loads text from sessionstorage if article.updated_at is newer', () => {
    const localStorageDate = new Date(dummyArticleUpdatedAt.getDate() - 1);
    localStorage.setItem(
      'editor-v2-http://localhost/',
      JSON.stringify({
        bodyMarkdown: 'hello, world',
        updatedAt: localStorageDate,
      }),
    );
    const form = shallow(getArticleForm());
    expect(form.state().bodyMarkdown).toBe('');
  });

  it('resets the post on reset press', () => {
    const form = shallow(getArticleForm());
    form.find('.clear').simulate('click');
    expect(form.state().bodyMarkdown).toBe('');
  });

  it('toggles help on help button press', () => {
    const form = deep(getArticleForm());
    global.scrollTo = jest.fn();
    form
      .find('.articleform__buttons--small')
      .simulate('click', { preventDefault: () => {} });
    expect(form.state().helpShowing).toBe(true);
    form
      .find('.articleform__buttons--small')
      .simulate('click', { preventDefault: () => {} });
    expect(form.state().helpShowing).toBe(false);
  });
});
