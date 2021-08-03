import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { Form } from '../Form';

let bodyMarkdown;
let mainImage;

// TODO: These image uploader axe custom rules here should be removed when the below issue is fixed
// https://github.com/forem/forem/issues/13947
const imageUploadAxeRules = {
  'nested-interactive': { enabled: false },
};

// Axe flags an error for the multi-line combobox we use for Autosuggest, since a combobox should be a single line input.
// This is a known issue documented on https://github.com/forem/forem/pull/13044, and these custom rules only apply to the two tests referencing them below.
const customAxeRules = {
  'aria-allowed-role': { enabled: false },
  'aria-required-children': { enabled: false },
  ...imageUploadAxeRules,
};

describe('<Form />', () => {
  beforeEach(() => {
    global.Runtime = {
      isNativeIOS: jest.fn(() => {
        return false;
      }),
    };

    global.window.matchMedia = jest.fn((query) => {
      return {
        matches: false,
        media: query,
        addListener: jest.fn(),
        removeListener: jest.fn(),
      };
    });
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
      const { queryByTestId, queryByLabelText, queryByAltText } = render(
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

      queryByTestId('article-form__body');

      expect(queryByAltText(/post cover/i)).toBeNull();
      expect(queryByTestId('article-form__title')).toBeNull();
      expect(queryByLabelText('Post Tags')).toBeNull();
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
      const { queryByTestId, getByLabelText, getByAltText } = render(
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

      getByAltText(/post cover/i);
      queryByTestId('article-form__title');
      getByLabelText('Post Tags');
      queryByTestId('article-form__body');

      const coverImageInput = getByLabelText('Change');

      // Allow any image format
      expect(coverImageInput.getAttribute('accept')).toEqual('image/*');

      // Ensure max file size
      expect(Number(coverImageInput.dataset.maxFileSizeMb)).toEqual(25);
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

    getByTestId('error-message');
    expect(getByTestId('error-message').textContent).toContain('title');
    expect(getByTestId('error-message').textContent).toContain('main_image');
  });
});
