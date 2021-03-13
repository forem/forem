import { h } from 'preact';
import { render } from '@testing-library/preact';
import fetch from 'jest-fetch-mock';
import { axe } from 'jest-axe';

import { EmailPreferencesForm } from '../EmailPreferencesForm';

global.fetch = fetch;

describe('EmailPreferencesForm', () => {
  const renderEmailPreferencesForm = () =>
    render(
      <EmailPreferencesForm
        next={jest.fn()}
        prev={jest.fn()}
        currentSlideIndex={4}
        slidesCount={5}
        communityConfig={{
          communityName: 'Community Name',
          communityLogo: '/x.png',
          communityBackground: '/y.jpg',
          communityDescription: 'Some community description',
        }}
        previousLocation={null}
      />,
    );

  const getUserData = () =>
    JSON.stringify({
      followed_tag_names: ['javascript'],
      profile_image_90: 'mock_url_link',
      name: 'firstname lastname',
      username: 'username',
    });

  beforeAll(() => {
    document.head.innerHTML =
      '<meta name="csrf-token" content="some-csrf-token" />';
    document.body.setAttribute('data-user', getUserData());
  });

  it('should have no a11y violations', async () => {
    const { container } = render(renderEmailPreferencesForm());
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should load the appropriate text', () => {
    const { queryByText } = renderEmailPreferencesForm();

    expect(queryByText(/almost there!/i)).toBeDefined();
    expect(
      queryByText(/review your email preferences before we continue./i),
    ).toBeDefined();
    expect(queryByText('Email preferences')).toBeDefined();
  });

  it('should show the two checkboxes unchecked', () => {
    const { queryByLabelText } = renderEmailPreferencesForm();

    expect(queryByLabelText(/receive weekly newsletter/i).checked).toBe(false);
    expect(queryByLabelText(/receive a periodic digest/i).checked).toBe(false);
  });

  it('should render a stepper', () => {
    const { queryByTestId } = renderEmailPreferencesForm();

    expect(queryByTestId('stepper')).toBeDefined();
  });

  it('should render a back button', () => {
    const { queryByTestId } = renderEmailPreferencesForm();

    expect(queryByTestId('back-button')).toBeDefined();
  });

  it('should render a button that says Finish', () => {
    const { queryByText } = renderEmailPreferencesForm();

    expect(queryByText('Finish')).toBeDefined();
  });
});
