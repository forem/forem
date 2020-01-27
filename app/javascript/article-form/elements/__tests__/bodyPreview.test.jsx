import { h } from 'preact';
import render from 'preact-render-to-json';
import { JSDOM } from 'jsdom';
import { shallow } from 'preact-render-spy';
import BodyPreview from '../bodyPreview';

const doc = new JSDOM('<!doctype html><html><body></body></html>');
global.document = doc;
global.window = doc.defaultView;
global.window.currentUser = {
  id: 1,
  name: 'Guy Fieri',
  username: 'guyfieri',
  profile_image_90:
    '/uploads/user/profile_image/41/0841dbe2-208c-4daa-b498-b2f01f3d37b2.png',
};

describe('<bodyPreview />', () => {
  let previewResponse;
  let articleState;

  beforeEach(() => {
    previewResponse = {
      processed_html:
        '<p>My Awesome Post! Not very long, but still very awesome.</p>↵↵',
      title: 'My Awesome Post',
      tags: null,
      cover_image: 'http://lorempixel.com/400/200/',
    };

    articleState = {
      id: 1,
      title: 'My Awesome Post',
      tagList: '',
      bodyMarkdown:
        '---↵title: My Awesome Post↵published: false↵description: ↵tags: ↵---↵↵My Awesome Post Not very long, but still very awesome! ↵',
      published: false,
      previewShowing: true,
      previewResponse,
    };
  });

  it('v1: renders properly', () => {
    const tree = render(
      <BodyPreview
        previewResponse={previewResponse}
        version="v1"
        articleState={articleState}
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('v2: renders properly', () => {
    const tree = render(
      <BodyPreview
        previewResponse={previewResponse}
        version="v2"
        articleState={articleState}
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('v1: shows a cover image in preview if one exists', () => {
    const container = shallow(
      <BodyPreview
        previewResponse={previewResponse}
        version="v1"
        articleState={articleState}
      />,
    );
    expect(container.find('.articleform__mainimagepreview').exists()).toEqual(
      true,
    );
  });

  it('v1: does not show a cover image in preview if one does not exist', () => {
    previewResponse.cover_image = null;
    const container = shallow(
      <BodyPreview
        previewResponse={previewResponse}
        version="v1"
        articleState={articleState}
      />,
    );
    expect(container.find('.articleform__mainimagepreview').exists()).toEqual(
      false,
    );
  });

  it('v2: shows a cover image in preview if one exists', () => {
    const container = shallow(
      <BodyPreview
        previewResponse={previewResponse}
        version="v2"
        articleState={articleState}
      />,
    );
    expect(container.find('.articleform__mainimagepreview').exists()).toEqual(
      true,
    );
  });

  it('v2: does not show a cover image in preview if one does not exist', () => {
    previewResponse.cover_image = null;
    const container = shallow(
      <BodyPreview
        previewResponse={previewResponse}
        version="v2"
        articleState={articleState}
      />,
    );
    expect(container.find('.articleform__mainimagepreview').exists()).toEqual(
      false,
    );
  });
});
