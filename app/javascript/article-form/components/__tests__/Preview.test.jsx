import { h } from 'preact';
import render from 'preact-render-to-json';
import { JSDOM } from 'jsdom';
import { shallow } from 'preact-render-spy';
import { Preview } from '../Preview';

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
let errors;

describe('<Preview />', () => {
  beforeEach(() => {
    previewResponse = {
      processed_html:
        '<p>My Awesome Post! Not very long, but still very awesome.</p>↵↵',
      title: 'My Awesome Post',
      tags: null,
      cover_image: 'http://lorempixel.com/400/200/',
    };

    articleState = {
      id: null,
      title: 'My Awesome Post',
      tagList: 'javascript, career, ',
      description: 'Some description',
      canonicalUrl: '',
      series: '',
      allSeries: ['Learn Something new a day'],
      bodyMarkdown:
        '---↵title: My Awesome Post↵published: false↵description: ↵tags: ↵---↵↵My Awesome Post Not very long, but still very awesome! ↵',
      submitting: false,
      editing: false,
      mainImage: '/i/9ca8kb1cu34mobypm5yx.png',
      organizations: [
        {
          id: 4,
          bg_color_hex: '',
          name: 'DEV',
          text_color_hex: '',
          profile_image_90:
            '/uploads/organization/profile_image/4/1689e7ae-6306-43cd-acba-8bde7ed80a17.JPG',
        },
      ],
      organizationId: null,
      errors: null,
      edited: true,
      updatedAt: null,
      version: 'v2',
      helpFor: null,
      helpPosition: null,
    };
    errors = null;
  });

  it('renders properly', () => {
    const tree = render(
      <Preview
        previewResponse={previewResponse}
        articleState={articleState}
        errors={errors}
      />,
    );
    expect(tree).toMatchSnapshot();
  });

  it('shows the correct title', () => {
    const container = shallow(
      <Preview
        previewResponse={previewResponse}
        articleState={articleState}
        errors={errors}
      />,
    );

    expect(container.find('.spec-article__title').text()).toEqual(
      previewResponse.title,
    );
  });

  it('shows the correct tags', () => {
    const container = shallow(
      <Preview
        previewResponse={previewResponse}
        articleState={articleState}
        errors={errors}
      />,
    );

    expect(container.find('.spec-article__tags').text()).toEqual(
      '#javascript#career',
    );
  });

  it('shows a cover image in the preview if one exists', () => {
    const container = shallow(
      <Preview
        previewResponse={previewResponse}
        articleState={articleState}
        errors={errors}
      />,
    );

    expect(container.find('.crayons-article__cover__image').exists()).toEqual(
      true,
    );
  });

  it('does not show a cover image in the preview if one does not exists', () => {
    previewResponse.cover_image = null;
    articleState.mainImage = null;

    const container = shallow(
      <Preview
        previewResponse={previewResponse}
        articleState={articleState}
        errors={errors}
      />,
    );

    expect(container.find('.crayons-article__cover__image').exists()).toEqual(
      false,
    );
  });

  // TODO: need to write a test for the cover image for v1
});
