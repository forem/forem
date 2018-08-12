import { h } from 'preact';
import render from 'preact-render-to-json';
import { shallow } from 'preact-render-spy';
import ArticleForm from '../articleForm';
import { JSDOM } from 'jsdom'

const doc = new JSDOM('<!doctype html><html><body></body></html>')
global.document = doc
global.window = doc.defaultView

global.document.body.createTextRange = function () {
  return {
    setEnd: function () { },
    setStart: function () { },
    getBoundingClientRect: function () {
      return { right: 0 };
    },
    getClientRects: function () {
      return {
        length: 0,
        left: 0,
        right: 0
      }
    }
  }
}
global.window.initEditorResize = jest.fn()

global.document.body.innerHTML = "<div id='editor-help-guide'></div>";

import algoliasearch from './__mocks__/algoliasearch'
global.window.algoliasearch = algoliasearch

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

    return context.component().handleTagKeyUp({ target: { value: 'git' } }).then(() => {
      expect(context.state()).toMatchSnapshot();
    })
  })
});
