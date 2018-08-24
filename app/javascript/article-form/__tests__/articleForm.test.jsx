import { h, render as preactRender } from 'preact';
import render from 'preact-render-to-json';
import { shallow, deep } from 'preact-render-spy';
import ArticleForm from '../articleForm';
import { JSDOM } from 'jsdom';
import algoliasearch from '../__mocks__/algoliasearch';

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
    global.window.initEditorResize = jest.fn();

    global.document.body.innerHTML = "<div id='editor-help-guide'></div>";

    global.window.algoliasearch = algoliasearch;
  });

  it('renders properly', () => {
    const tree = render(getArticleForm());
    expect(tree).toMatchSnapshot();
  });

  it('shows tags as you search', () => {
    const context = shallow(getArticleForm());
    const component = context.component();

    return component
      .handleTagInput({ target: { value: 'gi', selectionStart: 2 } })
      .then(() => {
        expect(context.state()).toMatchSnapshot();
      });
  });

  it('selects tag when you click on it', () => {
    const component = preactRender(
      getArticleForm(),
      document.body,
      document.body.firstElementChild,
    )._component;

    component.handleTagClick({ target: { dataset: { content: 'git' } } });
    expect(component.state).toMatchSnapshot();
  });

  it('replaces tag when editing', () => {
    const component = preactRender(
      getArticleForm(),
      document.body,
      document.body.firstElementChild,
    )._component;

    const input = document.getElementById('tag-input');
    input.value = 'java,javascript,linux';
    input.selectionStart = 2;

    component.handleTagClick({ target: { dataset: { content: 'git' } } });
    expect(component.state).toMatchSnapshot();
  });

  it('shows tags when editing', () => {
    const component = preactRender(
      getArticleForm(),
      document.body,
      document.body.firstElementChild,
    )._component;

    return component
      .handleTagInput({
        target: { value: 'gi,javascript,linux', selectionStart: 2 },
      })
      .then(() => {
        expect(component.state).toMatchSnapshot();
      });
  });

  it('only allows 4 tags', () => {
    const component = preactRender(
      getArticleForm(),
      document.body,
      document.body.firstElementChild,
    )._component;

    component.handleTagInput({
      target: { value: 'java,javascript,linux,productivity' },
    });
    component.handleTagKeyDown({ keyCode: 188, preventDefault: jest.fn() });
    expect(component.state).toMatchSnapshot();
  });
});

const getArticleForm = () => (
  <ArticleForm
    article={
        '{ "id": null, "body_markdown": null, "cached_tag_list": null, "main_image": null, "published": false, "title": null }'
      }
  />
  );
