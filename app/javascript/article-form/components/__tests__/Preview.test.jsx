import { h } from 'preact';
import { JSDOM } from 'jsdom';
import { render } from '@testing-library/preact';
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

  it('shows the correct title', () => {
    const { getByText } = render(
      <Preview
        previewResponse={previewResponse}
        articleState={articleState}
        errors={errors}
      />,
    );

    getByText(previewResponse.title);
  });

  it('shows the correct tags', () => {
    const { getByText } = render(
      <Preview
        previewResponse={previewResponse}
        articleState={articleState}
        errors={errors}
      />,
    );

    getByText(`javascript`);
    getByText(`career`);
  });

  it('shows a cover image in the preview if one exists', () => {
    const { getByTestId } = render(
      <Preview
        previewResponse={previewResponse}
        articleState={articleState}
        errors={errors}
      />,
    );

    getByTestId('article-form__cover');
  });

  it('does not show a cover image in the preview if one does not exist', () => {
    previewResponse.cover_image = null;
    articleState.mainImage = null;

    const { queryByTestId } = render(
      <Preview
        previewResponse={previewResponse}
        articleState={articleState}
        errors={errors}
      />,
    );

    expect(queryByTestId('article-form__cover')).toBeNull();
  });

  // TODO: need to write a test for the cover image for v1
});
