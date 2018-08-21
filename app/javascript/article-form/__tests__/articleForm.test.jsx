import { h, render as preactRender } from 'preact';
import render from 'preact-render-to-json';
import { shallow, deep } from 'preact-render-spy';
import ArticleForm from '../articleForm';
import { JSDOM } from 'jsdom';

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

import algoliasearch from './__mocks__/algoliasearch';

global.window.algoliasearch = algoliasearch;

describe('<ArticleForm />', () => {
  it('renders properly', () => {
    const tree = render(
      <ArticleForm
        article={
          '{ "id": null, "body_markdown": null, "cached_tag_list": null, "main_image": null, "published": false, "title": null }'
        }
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('shows tags as you search', () => {
    const context = shallow(
      <ArticleForm
        article={
          '{ "id": null, "body_markdown": null, "cached_tag_list": null, "main_image": null, "published": false, "title": null }'
        }
      />,
    );

    return context
      .component()
      .handleTagInput({ target: { value: 'gi', selectionStart: 2 } })
      .then(() => {
        expect(context.state()).toMatchSnapshot();
      });
  });

  it('selects tag when you click on it', () => {
    const component = preactRender(
      <ArticleForm
        article={
          '{ "id": null, "body_markdown": null, "cached_tag_list": null, "main_image": null, "published": false, "title": null }'
        }
      />,
      document.body,
      document.body.firstElementChild,
    )._component;

    component.handleTagClick({ target: { dataset: { content: 'git' } } });
    expect(component.state).toMatchSnapshot();
  });
});
