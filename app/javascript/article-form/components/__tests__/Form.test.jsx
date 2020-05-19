import { h } from 'preact';
import render from 'preact-render-to-json';
import { deep } from 'preact-render-spy';
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

    it('renders properly', () => {
      const tree = render(
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
      expect(tree).toMatchSnapshot();
    });

    it('displays the correct elements', () => {
      const container = deep(
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
      expect(container.find('.crayons-article-form__cover').exists()).toEqual(
        false,
      );
      expect(container.find('.crayons-article-form__title').exists()).toEqual(
        false,
      );
      expect(
        container.find('.crayons-article-form__tagsfield').exists(),
      ).toEqual(false);
      expect(container.find('.crayons-article-form__body').exists()).toEqual(
        true,
      );
    });
  });

  describe('v2', () => {
    beforeEach(() => {
      bodyMarkdown =
        '---↵title: Test Title v2↵published: false↵description: some description↵tags: javascript, career↵cover_image: https://dev-to-uploads.s3.amazonaws.com/uploads/badge/badge_image/12/8_week_streak-Shadow.png↵---↵↵Lets do this v2 changes↵↵![Alt Text](/i/12qpyywb0jlj6hksp9fn.png)';
      mainImage =
        'https://dev-to-uploads.s3.amazonaws.com/uploads/badge/badge_image/12/8_week_streak-Shadow.png';
    });

    it('renders properly', () => {
      const tree = render(
        <Form
          titleDefaultValue="Test Title v2"
          titleOnChange={null}
          tagsDefaultValue="javascript, career"
          tagsOnInput={null}
          bodyDefaultValue={bodyMarkdown}
          bodyOnChange={null}
          bodyHasFocus={false}
          version="v2"
          mainImage="https://dev-to-uploads.s3.amazonaws.com/uploads/badge/badge_image/12/8_week_streak-Shadow.png"
          onMainImageUrlChange={null}
          errors={null}
          switchHelpContext={null}
        />,
      );

      expect(tree).toMatchSnapshot();
    });

    it('displays the correct elements', () => {
      const container = deep(
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
      expect(container.find('.crayons-article-form__cover').exists()).toEqual(
        true,
      );
      expect(container.find('.crayons-article-form__title').exists()).toEqual(
        true,
      );
      expect(
        container.find('.crayons-article-form__tagsfield').exists(),
      ).toEqual(true);
      expect(container.find('.crayons-article-form__body').exists()).toEqual(
        true,
      );
    });
  });

  it('shows errors if there are any', () => {
    const errors = {
      title: ["can't be blank"],
      main_image: ['is not a valid URL'],
    };
    const container = deep(
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

    expect(container.find('.crayons-notice--danger').exists()).toEqual(true);
    expect(container.find('.crayons-notice--danger').text()).toMatch('title');
    expect(container.find('.crayons-notice--danger').text()).toMatch(
      'main_image',
    );
  });
});
