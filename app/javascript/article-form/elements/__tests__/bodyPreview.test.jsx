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

let previewResponse;
let articleState;

describe('<bodyPreview version="v1" />', () => {
  const version = 'v1';
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

  it('renders properly with an image', () => {
    const tree = render(
      <BodyPreview
        previewResponse={previewResponse}
        version={version}
        articleState={articleState}
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('shows an image in preview if one exists', () => {
    const container = shallow(
      <BodyPreview
        previewResponse={previewResponse}
        version={version}
        articleState={articleState}
      />,
    );
    expect(container.find('.articleform__mainimagepreview').exists()).toEqual(
      true,
    );
  });

  it('renders properly without an image', () => {
    previewResponse.cover_image = null;
    const tree = render(
      <BodyPreview
        previewResponse={previewResponse}
        version={version}
        articleState={articleState}
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('does not show an image in preview if one does not exist', () => {
    previewResponse.cover_image = null;
    const container = shallow(
      <BodyPreview
        previewResponse={previewResponse}
        version={version}
        articleState={articleState}
      />,
    );
    expect(container.find('.articleform__mainimagepreview').exists()).toEqual(
      false,
    );
  });
});

describe('<bodyPreview version="v2" />', () => {
  const version = 'v2';
  beforeEach(() => {
    previewResponse = {
      processed_html:
        '<p>My Awesome Post! Not very long, but still very awesome.</p>↵↵',
    };

    articleState = {
      id: 1,
      title: 'My Awesome Post',
      tagList: '',
      bodyMarkdown:
        '---↵title: My Awesome Post↵published: false↵description: ↵tags: ↵---↵↵My Awesome Post Not very long, but still very awesome! ↵',
      mainImage: 'http://lorempixel.com/400/200/',
      published: false,
      previewShowing: true,
      previewResponse,
    };
  });

  it('renders properly with an image', () => {
    const tree = render(
      <BodyPreview
        previewResponse={previewResponse}
        version={version}
        articleState={articleState}
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('shows an image in preview if one exists', () => {
    const container = shallow(
      <BodyPreview
        previewResponse={previewResponse}
        version={version}
        articleState={articleState}
      />,
    );
    expect(container.find('.articleform__mainimagepreview').exists()).toEqual(
      true,
    );
  });

  it('renders properly without an image', () => {
    articleState.mainImage = null;
    const tree = render(
      <BodyPreview
        previewResponse={previewResponse}
        version={version}
        articleState={articleState}
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('does not show an image in preview if one does not exist', () => {
    articleState.mainImage = null;
    const container = shallow(
      <BodyPreview
        previewResponse={previewResponse}
        version={version}
        articleState={articleState}
      />,
    );
    expect(container.find('.articleform__mainimagepreview').exists()).toEqual(
      false,
    );
  });
});
