import { h } from 'preact';
import { render } from '@testing-library/preact';
import { Form } from '../Form';

let bodyMarkdown; let mainImage;

describe('<Form />', () => {
  describe('v1', () => {
    beforeEach(() => {
      bodyMarkdown =
        '---↵title: Test Title v1↵published: false↵description: some description↵tags: javascript, career↵cover_image: https://dev-to-uploads.s3.amazonaws.com/uploads/user/profile_image/3/13d3b32a-d381-4549-b95e-ec665768ce8f.png↵---↵↵Lets do this v1 changes↵↵![Alt Text](/i/12qpyywb0jlj6hksp9fn.png)';
      mainImage =
        'https://dev-to-uploads.s3.amazonaws.com/uploads/user/profile_image/3/13d3b32a-d381-4549-b95e-ec665768ce8f.png';
    });

    it('displays the correct elements', () => {
      const { queryByTestId } = render(
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

      expect(queryByTestId('article-form__cover')).toBeNull();
      expect(queryByTestId('article-form__title')).toBeNull();
      expect(queryByTestId('article-form__tagsfield')).toBeNull();
      queryByTestId('article-form__body');
    });
  });

  describe('v2', () => {
    beforeEach(() => {
      bodyMarkdown =
        '---↵title: Test Title v2↵published: false↵description: some description↵tags: javascript, career↵cover_image: https://dev-to-uploads.s3.amazonaws.com/uploads/badge/badge_image/12/8_week_streak-Shadow.png↵---↵↵Lets do this v2 changes↵↵![Alt Text](/i/12qpyywb0jlj6hksp9fn.png)';
      mainImage =
        'https://dev-to-uploads.s3.amazonaws.com/uploads/badge/badge_image/12/8_week_streak-Shadow.png';
    });

    it('displays the correct elements', () => {
      const { queryByTestId } = render(
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

      queryByTestId('article-form__cover');
      queryByTestId('article-form__title');
      queryByTestId('article-form__tagsfield');
      queryByTestId('article-form__body');
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
