import { h } from 'preact';
import { JSDOM } from 'jsdom';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { Preview } from '../Preview';
import { useState } from 'preact/hooks';
import { Form } from '../Form';
import '@testing-library/jest-dom';

const doc = new JSDOM('<!doctype html><html><body></body></html>');
global.document = doc;
global.window = doc.defaultView;
global.window.currentUser = Object.freeze({
  id: 1,
  name: 'Guy Fieri',
  username: 'guyfieri',
  profile_image_90:
    '/uploads/user/profile_image/41/0841dbe2-208c-4daa-b498-b2f01f3d37b2.png',
});

let errors;

function getPreviewResponse() {
  return {
    processed_html:
      '<p>My Awesome Post! Not very long, but still very awesome.</p>↵↵',
    title: 'My Awesome Post',
    tags: null,
    cover_image: 'http://lorempixel.com/400/200/',
  };
}

function getArticleState() {
  return {
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
}

describe('<Preview />', () => {
  beforeEach(() => {
    errors = null;
  });

  it('should have no a11y violations when preview is loading', async () => {
    const { container } = render(
      <Preview
        previewLoading={false}
        previewResponse={getPreviewResponse()}
        articleState={getArticleState()}
        errors={errors}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should have no a11y violations when preview is displayed', async () => {
    const { container } = render(
      <Preview
        previewLoading={true}
        previewResponse={getPreviewResponse()}
        articleState={getArticleState()}
        errors={errors}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('does not show loading screen when preview is displayed', () => {
    const articleState = { ...getArticleState(), mainImage: null };
    const previewResponse = { ...getPreviewResponse(), cover_image: null };
    const { queryByTestId } = render(
      <Preview
        previewLoading={false}
        previewResponse={previewResponse}
        articleState={articleState}
        errors={errors}
      />,
    );

    expect(queryByTestId('loading-preview')).not.toBeInTheDocument();
  });

  it('shows loading screen when preview is loading', () => {
    const articleState = { ...getArticleState(), mainImage: null };
    const previewResponse = { ...getPreviewResponse(), cover_image: null };
    const { queryByTestId } = render(
      <Preview
        previewLoading={true}
        previewResponse={previewResponse}
        articleState={articleState}
        errors={errors}
      />,
    );

    expect(queryByTestId('loading-preview')).toBeInTheDocument();
  });

  it('shows loading with cover image when image is attached', () => {
    const { queryByTestId } = render(
      <Preview
        previewLoading={true}
        previewResponse={getPreviewResponse()}
        articleState={getArticleState()}
        errors={errors}
      />,
    );

    expect(queryByTestId('loading-preview__cover')).toBeInTheDocument();
  });

  it('shows preview loading without cover image loading', () => {
    const articleState = { ...getArticleState(), mainImage: null };
    const previewResponse = { ...getPreviewResponse(), cover_image: null };
    const { queryByTestId } = render(
      <Preview
        previewLoading={true}
        previewResponse={previewResponse}
        articleState={articleState}
        errors={errors}
      />,
    );

    expect(queryByTestId('loading-preview__cover')).not.toBeInTheDocument();
  });

  it('shows the correct title', () => {
    const previewResponse = getPreviewResponse();
    const { getByText } = render(
      <Preview
        previewResponse={previewResponse}
        articleState={getArticleState()}
        errors={errors}
      />,
    );

    expect(getByText(previewResponse.title)).toBeInTheDocument();
  });

  it('shows the correct tags', () => {
    const { getByText } = render(
      <Preview
        previewResponse={getPreviewResponse()}
        articleState={getArticleState()}
        errors={errors}
      />,
    );

    expect(getByText(`javascript`)).toBeInTheDocument();
    expect(getByText(`career`)).toBeInTheDocument();
  });

  it('shows a cover image in the preview if one exists', () => {
    const articleState = { ...getArticleState(), previewShowing: true };
    const { getByTestId, getByAltText } = render(
      <Preview
        previewResponse={getPreviewResponse()}
        articleState={articleState}
        errors={errors}
      />,
    );
    const coverImage = getByAltText(/post preview cover/i);

    expect(getByTestId('article-form__cover')).toBeInTheDocument();

    expect(coverImage.src).toEqual('http://lorempixel.com/400/200/');
  });

  it('does not show a cover image in the preview if one does not exist', () => {
    const articleState = { ...getArticleState(), mainImage: null };
    const previewResponse = { ...getPreviewResponse(), cover_image: null };
    const { queryByTestId } = render(
      <Preview
        previewResponse={previewResponse}
        articleState={articleState}
        errors={errors}
      />,
    );

    expect(queryByTestId('page-title__label')).not.toBeInTheDocument();
  });

  // TODO: need to write a test for the cover image for v1
});

// Integration test: Form stays mounted (invisible) when switching to Preview
describe('Preview + Form integration', () => {
  /**
   * This test simulates the real scenario where the Form is always rendered,
   * but hidden (display: none) when in Preview mode.
   * This ensures the browser keeps the undo/redo history alive.
   */
  function TestWrapper() {
    const [preview, setPreview] = useState(false);

    return (
      <div>
        <button onClick={() => setPreview((p) => !p)}>Toggle Preview</button>
        <div
          data-testid="form-container"
          style={{ display: preview ? 'none' : 'block' }}
        >
          <Form
            titleDefaultValue="Test"
            titleOnChange={() => {}}
            tagsDefaultValue="tag"
            tagsOnInput={() => {}}
            bodyDefaultValue="markdown"
            bodyOnChange={() => {}}
            bodyHasFocus={false}
            version="v2"
            mainImage={null}
            onMainImageUrlChange={() => {}}
            errors={null}
            switchHelpContext={() => {}}
            coverImageHeight="400"
            coverImageCrop="center"
            previewMode={preview}
          />
        </div>
        {preview && (
          <Preview
            previewLoading={false}
            previewResponse={{ processed_html: '<p>preview</p>' }}
            articleState={{}}
            errors={null}
          />
        )}
      </div>
    );
  }

  it('keeps the Form mounted in the DOM (but hidden) when switching to Preview mode', () => {
    const { getByText, getByTestId } = render(<TestWrapper />);
    // Form is visible initially
    expect(getByTestId('form-container')).toBeVisible();

    // Switch to preview mode
    getByText('Toggle Preview').click();

    // Form is still in the DOM, but not visible
    expect(getByTestId('form-container')).toBeInTheDocument();
    expect(getByTestId('form-container')).not.toBeVisible();
  });
});
