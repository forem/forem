import { h } from 'preact';
import { render } from '@testing-library/preact';
import { axe } from 'jest-axe';
import { Options } from '../Options';
import '@testing-library/jest-dom';

function getPassedData() {
  return {
    id: null,
    title: 'Test v2 Title',
    tagList: 'javascript, career, ',
    description: '',
    canonicalUrl: '',
    series: '',
    allSeries: ['Learn Something new a day'],
    bodyMarkdown:
      "![Alt Text](/i/wsq3lro2l66f87kqiqrf.jpeg)\nLet's write something here...",
    published: false,
    previewShowing: false,
    previewResponse: '',
    submitting: false,
    editing: false,
    mainImage: '/i/9pouqdqxcl4f6rwk1yfd.jpg',
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
    helpFor: 'article_body_markdown',
    helpPosition: 421,
  };
}

describe('<Options />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <Options
        passedData={getPassedData()}
        onConfigChange={null}
        onSaveDraft={null}
        moreConfigShowing={null}
        toggleMoreConfig={null}
        previewLoading={false}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should have no a11y violations when preview is loading', async () => {
    const { container } = render(
      <Options
        passedData={getPassedData()}
        onConfigChange={null}
        onSaveDraft={null}
        moreConfigShowing={null}
        toggleMoreConfig={null}
        previewLoading={true}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('shows the button is disabled when preview is loading', () => {
    const passedData = getPassedData();
    passedData.published = true;

    const { getByTitle } = render(
      <Options
        passedData={passedData}
        onConfigChange={null}
        onSaveDraft={null}
        moreConfigShowing={null}
        toggleMoreConfig={null}
        previewLoading={true}
      />,
    );

    expect(getByTitle('Post options')).toBeDisabled();
  });

  it('shows the button is enabled when preview is not loading', () => {
    const passedData = getPassedData();
    passedData.published = true;

    const { getByTitle } = render(
      <Options
        passedData={passedData}
        onConfigChange={null}
        onSaveDraft={null}
        moreConfigShowing={null}
        toggleMoreConfig={null}
        previewLoading={false}
      />,
    );

    expect(getByTitle('Post options')).not.toBeDisabled();
  });

  it('shows the danger zone once an article is published', () => {
    const passedData = getPassedData();
    passedData.published = true;

    const { getByText, getByTestId } = render(
      <Options
        passedData={passedData}
        onConfigChange={null}
        onSaveDraft={null}
        moreConfigShowing={null}
        toggleMoreConfig={null}
      />,
    );

    expect(getByTestId('options__danger-zone')).toBeInTheDocument();
    expect(getByText(/danger zone/i)).toBeInTheDocument();
    expect(getByText(/unpublish post/i)).toBeInTheDocument();
    expect(getByText(/done/i)).toBeInTheDocument();
  });

  it('unpublishes an article when the unpublish post button is clicked', () => {
    const passedData = getPassedData();
    passedData.published = true;

    const onSaveDraft = jest.fn();
    const { getByText } = render(
      <Options
        passedData={passedData}
        onConfigChange={null}
        onSaveDraft={onSaveDraft}
        moreConfigShowing={null}
        toggleMoreConfig={null}
      />,
    );

    const unpublishPostButton = getByText(/unpublish post/i);

    unpublishPostButton.click();

    expect(onSaveDraft).toHaveBeenCalledTimes(1);
  });
});
