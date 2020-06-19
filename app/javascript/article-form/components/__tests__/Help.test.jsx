import { h } from 'preact';
import { render } from '@testing-library/preact';
import { Help } from '../Help';

describe('<Help />', () => {
  it('does not render help if we are in preview mode', () => {
    const { queryByTestId } = render(<Help
      previewShowing
      helpFor={null}
      helpPosition={null}
      version="v1"
    />);
    expect(queryByTestId('article-form__help-section')).toBeNull();
  });

  it('shows some help in edit mode', () => {
    const { getByTestId } = render(
      <Help
        previewShowing={false}
        helpFor={null}
        helpPosition={null}
        version="v1"
      />,
    );
    getByTestId('article-form__help-section');
  });

  it('shows the correct help for v1', () => {
    const { queryByTestId } = render(
      <Help
        previewShowing={false}
        helpFor={null}
        helpPosition={null}
        version="v1"
      />,
    );

    queryByTestId('article-form__help-section');
    queryByTestId('basic-editor-help');
    queryByTestId('format-help');
    expect(queryByTestId('title-help')).toBeNull();
    expect(queryByTestId('basic-tag-input-help')).toBeNull();
  });

  describe('with the appropriate v2 help sections', () => {

    it('shows the article-form-title', () => {
      const { queryByTestId } = render(
        <Help
          previewShowing={false}
          helpFor="article-form-title"
          helpPosition={null}
          version="v2"
        />,
      );

      queryByTestId('article-form__help-section');
      expect(queryByTestId('basic-editor-help')).toBeNull();
      expect(queryByTestId('format-help')).toBeNull();
      queryByTestId('title-help');
      expect(queryByTestId('basic-tag-input-help')).toBeNull();
    });

    it('shows the article_body_markdown', () => {
      const {queryByTestId} = render(
        <Help
          previewShowing={false}
          helpFor="article_body_markdown"
          helpPosition={null}
          version="v2"
        />,
      );

      queryByTestId('article-form__help-section');
      expect(queryByTestId('basic-editor-help')).toBeNull();
      queryByTestId('format-help');
      expect(queryByTestId('title-help')).toBeNull();
      expect(queryByTestId('basic-tag-input-help')).toBeNull();
    });

    it('shows the tag-input', () => {
      const { queryByTestId } = render(
        <Help
          previewShowing={false}
          helpFor="tag-input"
          helpPosition={null}
          version="v2"
        />,
      );

      queryByTestId('article-form__help-section');
      expect(queryByTestId('basic-editor-help')).toBeNull();
      expect(queryByTestId('format-help')).toBeNull();
      expect(queryByTestId('title-help')).toBeNull();
      queryByTestId('basic-tag-input-help');
    });

  });

  // TODO: test the modals

});
