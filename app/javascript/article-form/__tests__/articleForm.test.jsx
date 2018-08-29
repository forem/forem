import { h, render as preactRender } from 'preact';
import render from 'preact-render-to-json';
import { shallow, deep } from 'preact-render-spy';
import ArticleForm from '../articleForm';
import { JSDOM } from 'jsdom';
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
    global.window.initEditorResize = jest.fn();

    global.document.body.innerHTML = "<div id='editor-help-guide'></div>";

    global.window.algoliasearch = algoliasearch;
  });

  it('renders properly', () => {
    const tree = render(getArticleForm());
    expect(tree).toMatchSnapshot();
  });
});

const getArticleForm = () => (
  <ArticleForm
    article={
      '{ "id": null, "body_markdown": null, "cached_tag_list": null, "main_image": null, "published": false, "title": null }'
    }
  />
);
