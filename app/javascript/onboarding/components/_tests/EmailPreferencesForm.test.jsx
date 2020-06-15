import { h } from 'preact';
import { render } from '@testing-library/preact';
import fetch from 'jest-fetch-mock';

import EmailPreferencesForm from '../EmailPreferencesForm';

global.fetch = fetch;

describe('EmailPreferencesForm', () => {
  const renderEmailPreferencesForm = () => render(
    <EmailPreferencesForm
      next={jest.fn()}
      prev={jest.fn()}
      currentSlideIndex={4}
      slidesCount={5}
      communityConfig={{
        communityName: 'Community Name',
        communityLogo: '/x.png',
        communityBackground: '/y.jpg',
        communityDescription: "Some community description",
      }}
      previousLocation={null}
    />
  );

  const getUserData = () =>
    JSON.stringify({
      followed_tag_names: ['javascript'],
      profile_image_90: 'mock_url_link',
      name: 'firstname lastname',
      username: 'username',
    });
  const { location } = window;

  beforeAll(() => {
    document.head.innerHTML = '<meta name="csrf-token" content="some-csrf-token" />';
    document.body.setAttribute('data-user', getUserData());
  });

  it('should load the appropriate text', () => {
    const { getByText } = renderEmailPreferencesForm();

    getByText(/almost there!/i);
    getByText(/review your email preferences before we continue./i);
    getByText('Email preferences');
  });

  it('should show the two checkboxes', () => {
    const { getByLabelText } = renderEmailPreferencesForm();
    getByLabelText(/receive weekly newsletter/i);
    getByLabelText(/receive a periodic digest/i);
  });

  it('should render a stepper', () => {
    const { queryByTestId } = renderEmailPreferencesForm();
    queryByTestId('stepper')
  });

  it('should render a back button', () => {
    const { getByTestId } = renderEmailPreferencesForm();
    getByTestId('back-button');
  });

  it('should render a button that says Finish', () => {
    const { getByText } = renderEmailPreferencesForm();
    getByText('Finish');
  })

});
