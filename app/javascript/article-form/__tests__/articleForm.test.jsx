import { h, render as preactRender } from 'preact';
import render from 'preact-render-to-json';
import { shallow, deep } from 'preact-render-spy';
import { JSDOM } from 'jsdom';
import ArticleForm from '../articleForm';
import algoliasearch from '../elements/__mocks__/algoliasearch';

describe('<ArticleForm />', () => {
  beforeEach(() => {
    const doc = new JSDOM('<!doctype html><html><body></body></html>');
    global.document = doc;
    global.window = doc.defaultView;

    global.document.body.createTextRange = function() {
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
      JSON.stringify({ bodyMarkdown: 'hello, world' }),
    );
    const form = shallow(getArticleForm());
    expect(form.state().bodyMarkdown).toBe('hello, world');
  });

  it('resets the post on reset press', () => {
    const form = shallow(getArticleForm());
    form.find('.clear').simulate('click');
    expect(form.state().bodyMarkdown).toBe('');
  });
});

const getArticleForm = () => (
  <ArticleForm
    version="v2"
    article={
      '{ "id": null, "body_markdown": null, "cached_tag_list": null, "main_image": null, "published": false, "title": null }'
    }
  />
);
