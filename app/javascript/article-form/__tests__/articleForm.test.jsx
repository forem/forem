import { h } from 'preact';
import render from 'preact-render-to-json';
import ArticleForm from '../articleForm';

describe('<ArticleForm />', () => {
  it('renders properly', () => {
    document.head.innerHTML =
      "<meta name='algolia-public-id' content='abc123' />" +
      "<meta name='algolia-public-key' content='abc123' />" +
      "<meta name='environment' content='test' />";
    document.body.innerHTML = "<div id='editor-help-guide'></div>";

    const client = {
      initIndex: jest.fn(),
    };
    window.algoliasearch = jest.fn().mockImplementation((id, key) => client);

    const tree = render(
      <ArticleForm
        article={
          '{ "id": null, "body_markdown": null, "cached_tag_list": null, "main_image": null, "published": false, "title": null }'
        }
      />,
    );
    expect(tree).toMatchSnapshot();
  });
});
