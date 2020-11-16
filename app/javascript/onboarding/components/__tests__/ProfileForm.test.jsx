import { h } from 'preact';
import { render, fireEvent } from '@testing-library/preact';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';
import { axe } from 'jest-axe';

import ProfileForm from '../ProfileForm';

global.fetch = fetch;

describe('ProfileForm', () => {
  const renderProfileForm = () =>
    render(
      <ProfileForm
        next={jest.fn()}
        prev={jest.fn()}
        currentSlideIndex={2}
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
    const { container } = render(renderProfileForm());
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should load the appropriate title and subtitle', () => {
    const { getByTestId, getByText } = renderProfileForm();

    getByText(/Build your profile/i);
    expect(getByTestId('onboarding-profile-subtitle')).toHaveTextContent(
      /Tell us a little bit about yourself — this is how others will see you on Community Name. You’ll always be able to edit this later in your Settings./i,
    );
  });

  it('should show the correct name and username', () => {
    const { queryByText } = renderProfileForm();

    expect(queryByText('username')).toBeDefined();
    expect(queryByText('firstname lastname')).toBeDefined();
  });

  it('should show the correct profile picture', () => {
    const { getByAltText } = renderProfileForm();
    const img = getByAltText('profile');
    expect(img).toHaveAttribute('src');
    expect(img.getAttribute('src')).toEqual('mock_url_link');
  });

  it('shows the correct input with a label', () => {
    const { getByLabelText } = renderProfileForm();

    const bioInput = getByLabelText(/Bio/i);
    expect(bioInput.getAttribute('placeholder')).toEqual(
      'Tell us about yourself',
    );

    const locationInput = getByLabelText(/Where are you located/i);
    expect(locationInput.getAttribute('type')).toEqual('text');
    expect(locationInput.getAttribute('placeholder')).toEqual(
      'e.g. New York, NY',
    );
    expect(locationInput.getAttribute('maxLength')).toEqual('60');

    const employmentInput = getByLabelText(/What is your title/i);
    expect(employmentInput.getAttribute('type')).toEqual('text');
    expect(employmentInput.getAttribute('placeholder')).toEqual(
      'e.g. Software Engineer',
    );
    expect(employmentInput.getAttribute('maxLength')).toEqual('60');

    const employerName = getByLabelText(/Where do you work/i);
    expect(employerName.getAttribute('type')).toEqual('text');
    expect(employerName.getAttribute('placeholder')).toEqual(
      'e.g. Company name, self-employed, etc.',
    );
    expect(employerName.getAttribute('maxLength')).toEqual('60');
  });

  it('should render a stepper', () => {
    const { queryByTestId } = renderProfileForm();

    expect(queryByTestId('stepper')).toBeDefined();
  });

  it('should show the back button', () => {
    const { queryByTestId } = renderProfileForm();

    expect(queryByTestId('back-button')).toBeDefined();
  });

  it('should update the text on the forward button', async () => {
    const {
      getByLabelText,
      getByText,
      queryByText,
      findByLabelText,
      findByText,
    } = renderProfileForm();

    // input the bio
    const bioInput = getByLabelText(/Bio/i);
    expect(bioInput.value).toEqual('');
    getByText(/skip for now/i);
    expect(queryByText(/continue/i)).toBeNull();

    fireEvent.keyDown(bioInput, {
      key: 'Enter',
      keyCode: 13,
      which: 13,
      target: { value: 'Some biography' },
    });
    expect(bioInput.value).toEqual('Some biography');

    // input the location too (since we're using firevent and it doesn't call the focus events
    // that will trigger the continue )
    let locationInput = getByLabelText(/Where are you located/i);
    expect(locationInput.value).toEqual('');
    fireEvent.keyDown(locationInput, {
      key: 'Enter',
      keyCode: 13,
      which: 13,
      target: { value: 'Some location' },
    });

    locationInput = await findByLabelText(/Where are you located/i);

    expect(locationInput.value).toEqual('Some location');

    findByText(/continue/i);
  });
});
