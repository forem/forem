import { h } from 'preact';
import { render } from '@testing-library/preact';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';
import { axe } from 'jest-axe';

import { ProfileForm } from '../ProfileForm';

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

  const fakeGroupsResponse = JSON.stringify({
    profile_field_groups: [
      {
        id: 3,
        name: 'Work',
        description: null,
        profile_fields: [
          {
            id: 36,
            attribute_name: 'education',
            description: '',
            input_type: 'text_field',
            label: 'Education',
            placeholder_text: '',
          },
        ],
      },
      {
        id: 1,
        name: 'Basic',
        description: null,
        profile_fields: [
          {
            id: 31,
            attribute_name: 'name',
            description: '',
            input_type: 'text_field',
            label: 'Name',
            placeholder_text: 'John Doe',
          },
          {
            id: 32,
            attribute_name: 'website_url',
            description: '',
            input_type: 'text_field',
            label: 'Website URL',
            placeholder_text: 'https://yoursite.com',
          },
        ],
      },
    ],
  });

  beforeAll(() => {
    document.head.innerHTML =
      '<meta name="csrf-token" content="some-csrf-token" />';
    document.body.setAttribute('data-user', getUserData());
    fetch.mockResponse(fakeGroupsResponse);
    const csrfToken = 'this-is-a-csrf-token';
    global.getCsrfToken = async () => csrfToken;
  });

  it('should have no a11y violations', async () => {
    const { container } = renderProfileForm();
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

  it('should render the correct group headings', async () => {
    const { findByText } = renderProfileForm();

    const heading1 = await findByText('Education');
    const heading2 = await findByText('Name');

    expect(heading1).toBeInTheDocument();
    expect(heading2).toBeInTheDocument();
  });

  it('should render the correct fields', async () => {
    const { findByLabelText } = renderProfileForm();

    const field1 = await findByLabelText(/Education/i);
    const field2 = await findByLabelText(/^Name/i);
    const field3 = await findByLabelText(/Website URL/i);
    const field4 = await findByLabelText(/Username/i);

    expect(field1).toBeInTheDocument();
    expect(field2).toBeInTheDocument();
    expect(field2.getAttribute('placeholder')).toEqual('John Doe');
    expect(field3).toBeInTheDocument();
    expect(field3.getAttribute('placeholder')).toEqual('https://yoursite.com');
    expect(field4).toBeInTheDocument();
    expect(field4.getAttribute('value')).toEqual('username');
  });

  it('should render a stepper', () => {
    const { queryByTestId } = renderProfileForm();

    expect(queryByTestId('stepper')).toBeDefined();
  });

  it('should show the back button', () => {
    const { queryByTestId } = renderProfileForm();

    expect(queryByTestId('back-button')).toBeDefined();
  });

  it('should not be skippable', async () => {
    const { getByText } = renderProfileForm();

    expect(getByText(/continue/i)).toBeInTheDocument();
  });
});
