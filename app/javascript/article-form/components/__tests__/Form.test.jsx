import { h } from 'preact';
import { render, waitFor } from '@testing-library/preact';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';
import userEvent from '@testing-library/user-event';
import { axe } from 'jest-axe';
import { Form } from '../Form';

fetch.enableMocks();

// Mock Algolia
jest.mock('algoliasearch/lite', () => {
  const searchClient = {
    initIndex: jest.fn(() => ({
      search: jest.fn().mockResolvedValue({ hits: [] })
    }))
  };
  return jest.fn(() => searchClient);
});

const customAxeRules = {
  'aria-allowed-role': { enabled: false },
  'aria-required-children': { enabled: false },
};

describe('<Form />', () => {
  beforeEach(() => {
    fetch.resetMocks();

    global.Runtime = {
      isNativeIOS: jest.fn(() => {
        return false;
      }),
      getOSKeyboardModifierKeyString: jest.fn(() => 'cmd'),
    };

    global.window.matchMedia = jest.fn((query) => {
      return {
        matches: false,
        media: query,
        addListener: jest.fn(),
        removeListener: jest.fn(),
      };
    });

    document.body.dataset.algoliaId = 'testAlgoliaId';
    document.body.dataset.algoliaSearchKey = 'testAlgoliaSearchKey';
    const meta = document.createElement('meta');
    meta.name = 'environment';
    meta.content = 'testEnv';
    document.head.appendChild(meta);

    window.fetch = fetch;
    window.getCsrfToken = async () => 'this-is-a-csrf-token';

    fetch.mockResponse((req) =>
      Promise.resolve(
        req.url.includes('/tags/suggest')
          ? '[]'
          : JSON.stringify({ result: [] }),
      ),
    );
  });

  describe('v1', () => {
    beforeEach(() => {
      bodyMarkdown =
        '---↵title: Test Title v1↵published: false↵description: some description↵tags: javascript, career↵cover_image: https://dev-to-uploads.s3.amazonaws.com/uploads/user/profile_image/3/13d3b32a-d381-4549-b95e-ec665768ce8f.png↵---↵↵Lets do this v1 changes↵↵![Alt Text](/i/12qpyywb0jlj6hksp9fn.png)';
      mainImage =
        'https://dev-to-uploads.s3.amazonaws.com/uploads/user/profile_image/3/13d3b32a-d381-4549-b95e-ec665768ce8f.png';
    });

    it('should have no a11y violations', async () => {
      const { container } = render(
        <Form
          titleDefaultValue="Test Title v1"
          titleOnChange={null}
          tagsDefaultValue="javascript, career"
          tagsOnInput={null}
          bodyDefaultValue={bodyMarkdown}
          bodyOnChange={null}
          bodyHasFocus={false}
          version="v1"
          mainImage={mainImage}
          onMainImageUrlChange={null}
          errors={null}
          switchHelpContext={null}
        />,
      );

      const results = await axe(container, {
        rules: customAxeRules,
      });

      expect(results).toHaveNoViolations();
    });

    it('renders the v1 form', () => {
      const { queryByTestId, queryByLabelText, queryByAltText, getByTestId } =
        render(
          <Form
            titleDefaultValue="Test Title v1"
            titleOnChange={null}
            tagsDefaultValue="javascript, career"
            tagsOnInput={null}
            bodyDefaultValue={bodyMarkdown}
            bodyOnChange={null}
            bodyHasFocus={false}
            version="v1"
            mainImage={mainImage}
            onMainImageUrlChange={null}
            errors={null}
            switchHelpContext={null}
          />,
        );

      expect(getByTestId('article-form__body')).toBeInTheDocument();
      expect(queryByAltText(/post cover/i)).not.toBeInTheDocument();
      expect(queryByTestId('article-form__title')).not.toBeInTheDocument();
      expect(queryByLabelText('Post Tags')).not.toBeInTheDocument();
    });
  });

  describe('v2', () => {
    beforeEach(() => {
      bodyMarkdown =
        '---↵title: Test Title v2↵published: false↵description: some description↵tags: javascript, career↵cover_image: https://dev-to-uploads.s3.amazonaws.com/uploads/badge/badge_image/12/8_week_streak-Shadow.png↵---↵↵Lets do this v2 changes↵↵![Alt Text](/i/12qpyywb0jlj6hksp9fn.png)';
      mainImage =
        'https://dev-to-uploads.s3.amazonaws.com/uploads/badge/badge_image/12/8_week_streak-Shadow.png';
    });

    it('should have no a11y violations', async () => {
      const { container } = render(
        <Form
          titleDefaultValue="Test Title v2"
          titleOnChange={null}
          tagsDefaultValue="javascript, career"
          tagsOnInput={null}
          bodyDefaultValue={bodyMarkdown}
          bodyOnChange={null}
          bodyHasFocus={false}
          version="v2"
          mainImage={mainImage}
          onMainImageUrlChange={null}
          errors={null}
          switchHelpContext={null}
        />,
      );
      const results = await axe(container, {
        rules: customAxeRules,
      });

      expect(results).toHaveNoViolations();
    });

    it('renders the v2 form', () => {
      const { getByTestId, getByRole, getByLabelText } = render(
        <Form
          titleDefaultValue="Test Title v2"
          titleOnChange={null}
          tagsDefaultValue="javascript, career"
          tagsOnInput={null}
          bodyDefaultValue={bodyMarkdown}
          bodyOnChange={null}
          bodyHasFocus={false}
          version="v2"
          mainImage={mainImage}
          onMainImageUrlChange={null}
          errors={null}
          switchHelpContext={null}
        />,
      );

      expect(getByRole('img', { name: /post cover/i })).toBeInTheDocument();
      expect(getByRole('textbox', { name: /post title/i })).toBeInTheDocument();
      expect(
        getByRole('textbox', { name: 'Add up to 4 tags' }),
      ).toBeInTheDocument();
      expect(getByTestId('article-form__body')).toBeInTheDocument();

      const coverImageInput = getByLabelText('Change', { exact: false });

      // Allow any image format
      expect(coverImageInput.getAttribute('accept')).toEqual('image/*');

      // Ensure max file size
      expect(Number(coverImageInput.dataset.maxFileSizeMb)).toEqual(25);
    });

    it('renders a toolbar of markdown formatters', () => {
      const { getByRole } = render(
        <Form
          titleDefaultValue="Test Title v2"
          titleOnChange={null}
          tagsDefaultValue="javascript, career"
          tagsOnInput={null}
          bodyDefaultValue=""
          bodyOnChange={null}
          bodyHasFocus={false}
          version="v2"
          mainImage={mainImage}
          onMainImageUrlChange={null}
          errors={null}
          switchHelpContext={null}
        />,
      );

      const textArea = getByRole('textbox', { name: /Post Content/ });

      getByRole('button', { name: 'Bold' }).click();
      expect(textArea.value).toEqual('****');
      userEvent.clear(textArea);

      getByRole('button', { name: 'Italic' }).click();
      expect(textArea.value).toEqual('__');
      userEvent.clear(textArea);

      getByRole('button', { name: 'Link' }).click();
      expect(textArea.value).toEqual('[](url)');
      userEvent.clear(textArea);

      getByRole('button', { name: 'Ordered list' }).click();
      expect(textArea.value).toEqual('1. \n');
      userEvent.clear(textArea);

      getByRole('button', { name: 'Unordered list' }).click();
      expect(textArea.value).toEqual('- \n');
      userEvent.clear(textArea);

      getByRole('button', { name: 'Heading' }).click();
      expect(textArea.value).toEqual('## \n');
      userEvent.clear(textArea);

      getByRole('button', { name: 'Quote' }).click();
      expect(textArea.value).toEqual('> \n');
      userEvent.clear(textArea);

      getByRole('button', { name: 'Code' }).click();
      expect(textArea.value).toEqual('``');
      userEvent.clear(textArea);

      getByRole('button', { name: 'Code block' }).click();
      expect(textArea.value).toEqual('```\n\n```\n');
      userEvent.clear(textArea);
    });

    it('renders an overflow menu of markdown formatters', async () => {
      const { getByRole } = render(
        <Form
          titleDefaultValue="Test Title v2"
          titleOnChange={null}
          tagsDefaultValue="javascript, career"
          tagsOnInput={null}
          bodyDefaultValue=""
          bodyOnChange={null}
          bodyHasFocus={false}
          version="v2"
          mainImage={mainImage}
          onMainImageUrlChange={null}
          errors={null}
          switchHelpContext={null}
        />,
      );

      const textArea = getByRole('textbox', { name: 'Post Content' });
      const overflowMenuButton = getByRole('button', { name: 'More options' });

      overflowMenuButton.click();
      await waitFor(() =>
        expect(overflowMenuButton).toHaveAttribute('aria-expanded', 'true'),
      );

      getByRole('menuitem', { name: 'Underline' }).click();
      expect(textArea.value).toEqual('<u></u>');
      userEvent.clear(textArea);
      await waitFor(() =>
        expect(overflowMenuButton).toHaveAttribute('aria-expanded', 'false'),
      );

      getByRole('button', { name: 'More options' }).click();
      await waitFor(() =>
        expect(overflowMenuButton).toHaveAttribute('aria-expanded', 'true'),
      );

      getByRole('menuitem', { name: 'Strikethrough' }).click();
      expect(textArea.value).toEqual('~~~~');
      userEvent.clear(textArea);
      await waitFor(() =>
        expect(overflowMenuButton).toHaveAttribute('aria-expanded', 'false'),
      );

      getByRole('button', { name: 'More options' }).click();
      await waitFor(() =>
        expect(overflowMenuButton).toHaveAttribute('aria-expanded', 'true'),
      );

      getByRole('menuitem', { name: 'Line divider' }).click();
      expect(textArea.value).toEqual('---\n\n');
      userEvent.clear(textArea);
      await waitFor(() =>
        expect(overflowMenuButton).toHaveAttribute('aria-expanded', 'false'),
      );

      getByRole('button', { name: 'More options' }).click();
      await waitFor(() =>
        expect(overflowMenuButton).toHaveAttribute('aria-expanded', 'true'),
      );
      expect(getByRole('menuitem', { name: 'Help' })).toBeInTheDocument();
    });
  });

  it('shows errors if there are any', () => {
    const errors = {
      title: ["can't be blank"],
      main_image: ['is not a valid URL'],
    };
    const { getByTestId } = render(
      <Form
        titleDefaultValue="Test Title v2"
        titleOnChange={null}
        tagsDefaultValue="javascript, career"
        tagsOnInput={null}
        bodyDefaultValue={bodyMarkdown}
        bodyOnChange={null}
        bodyHasFocus={false}
        version="v2"
        mainImage={mainImage}
        onMainImageUrlChange={null}
        errors={errors}
        switchHelpContext={null}
      />,
    );

    const errorMsg = getByTestId('error-message');
    expect(errorMsg.textContent).toContain('title');
    expect(errorMsg.textContent).toContain('main_image');
  });
});
