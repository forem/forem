import { h } from 'preact';
import { render, within } from '@testing-library/preact';
import '@testing-library/jest-dom';
import { axe } from 'jest-axe';
import { Help } from '../Help';

describe('<Help />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <Help
        previewShowing={false}
        helpFor={null}
        helpPosition={null}
        version="v1"
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('does not render help if we are in preview mode', () => {
    const { queryByTestId } = render(
      <Help previewShowing helpFor={null} helpPosition={null} version="v1" />,
    );
    expect(queryByTestId('article-form__help-section')).not.toBeInTheDocument();
  });

  it('shows help for the given section when in edit mode', () => {
    const { getByTestId, getByRole } = render(
      <Help
        previewShowing={false}
        helpFor="article-form-title"
        helpPosition={null}
        version="v1"
      />,
    );
    const articleTitle = within(getByTestId('title-help'));

    expect(getByTestId('article-form__help-section')).toBeInTheDocument();
    expect(
      getByRole('heading', { name: /writing a great post title/i }),
    ).toBeInTheDocument();

    expect(
      articleTitle.getByText(
        'Think of your post title as a super short (but compelling!) description — like an overview of the actual post in one short sentence.',
      ),
    ).toBeInTheDocument();

    expect(
      articleTitle.getByText(
        'Use keywords where appropriate to help ensure people can find your post by search.',
      ),
    ).toBeInTheDocument();
  });

  it('shows the correct help for v1', () => {
    const { queryByTestId, getByTestId } = render(
      <Help
        previewShowing={false}
        helpFor={null}
        helpPosition={null}
        version="v1"
      />,
    );

    expect(getByTestId('article-form__help-section')).toBeInTheDocument();
    expect(getByTestId('basic-editor-help')).toBeInTheDocument();
    expect(getByTestId('format-help')).toBeInTheDocument();
    expect(getByTestId('article-publishing-tips')).toBeInTheDocument();

    expect(queryByTestId('title-help')).not.toBeInTheDocument();
    expect(queryByTestId('basic-tag-input-help')).not.toBeInTheDocument();
  });

  describe('with the appropriate v2 help sections', () => {
    it('shows the article-form-title', () => {
      const { queryByTestId, getByTestId } = render(
        <Help
          previewShowing={false}
          helpFor="article-form-title"
          helpPosition={null}
          version="v2"
        />,
      );

      expect(getByTestId('article-form__help-section')).toBeInTheDocument();
      expect(getByTestId('title-help')).toBeInTheDocument();

      expect(queryByTestId('basic-editor-help')).not.toBeInTheDocument();
      expect(queryByTestId('format-help')).not.toBeInTheDocument();
      expect(queryByTestId('basic-tag-input-help')).not.toBeInTheDocument();
    });

    it('shows the article_body_markdown', () => {
      const { queryByTestId, getByTestId } = render(
        <Help
          previewShowing={false}
          helpFor="article_body_markdown"
          helpPosition={null}
          version="v2"
        />,
      );

      expect(getByTestId('article-form__help-section')).toBeInTheDocument();
      expect(getByTestId('format-help')).toBeInTheDocument();

      expect(queryByTestId('basic-editor-help')).not.toBeInTheDocument();
      expect(queryByTestId('title-help')).not.toBeInTheDocument();
      expect(queryByTestId('basic-tag-input-help')).not.toBeInTheDocument();
    });

    it('shows the tag-input', () => {
      const { queryByTestId, getByTestId } = render(
        <Help
          previewShowing={false}
          helpFor="tag-input"
          helpPosition={null}
          version="v2"
        />,
      );

      expect(queryByTestId('article-form__help-section')).toBeInTheDocument();
      expect(getByTestId('basic-tag-input-help')).toBeInTheDocument();

      expect(queryByTestId('basic-editor-help')).not.toBeInTheDocument();
      expect(queryByTestId('format-help')).not.toBeInTheDocument();
      expect(queryByTestId('title-help')).not.toBeInTheDocument();
    });
  });

  // TODO: test the modals
});
