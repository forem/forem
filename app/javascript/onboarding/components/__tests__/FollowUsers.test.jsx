import { h } from 'preact';
import { render } from '@testing-library/preact';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';

import { axe } from 'jest-axe';
import { FollowUsers } from '../FollowUsers';

global.fetch = fetch;

describe('FollowUsers', () => {
  const renderFollowUsers = () =>
    render(
      <FollowUsers
        next={jest.fn()}
        prev={jest.fn()}
        currentSlideIndex={3}
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

  const fakeUsersResponse = JSON.stringify([
    {
      id: 1,
      name: 'Ben Halpern',
      profile_image_url: 'apple-icon.png',
    },
    {
      id: 2,
      name: 'Krusty the Clown',
      profile_image_url: 'clown.jpg',
    },
    {
      id: 3,
      name: 'dev.to staff',
      profile_image_url: 'dev.jpg',
    },
  ]);

  beforeAll(() => {
    document.head.innerHTML =
      '<meta name="csrf-token" content="some-csrf-token" />';
    document.body.setAttribute('data-user', getUserData());
  });

  it('should have no a11y violations when rendering users', async () => {
    fetch.mockResponseOnce(fakeUsersResponse);

    const { container } = renderFollowUsers();
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render the correct users', async () => {
    fetch.mockResponseOnce(fakeUsersResponse);
    const { findByText } = renderFollowUsers();

    const user1 = await findByText(/Ben Halpern/i);
    const user2 = await findByText(/Krusty the Clown/i);
    const user3 = await findByText(/dev.to staff/i);

    expect(user1).toBeInTheDocument();
    expect(user2).toBeInTheDocument();
    expect(user3).toBeInTheDocument();
  });

  it('should render the correct navigation button on first load', () => {
    fetch.mockResponseOnce(fakeUsersResponse);

    const { queryByText } = renderFollowUsers();

    expect(queryByText(/skip for now/i)).toBeDefined();
  });

  it('should update the navigation button text and follow status when you follow users', async () => {
    fetch.mockResponse(fakeUsersResponse);

    const { queryByText, findByText, findAllByTestId } = renderFollowUsers();

    const userButtons = await findAllByTestId(
      'onboarding-user-following-status',
    );

    expect(queryByText(/skip for now/i)).toBeDefined();
    expect(queryByText(/You're not following anyone/i)).toBeDefined();

    // follow the first user
    const firstUser = userButtons[0];
    firstUser.click();

    await findByText('Following');

    expect(queryByText(/You're following 1 person/i)).toBeDefined();
    expect(queryByText(/continue/i)).toBeDefined();

    // follow the second user
    const secondUser = userButtons[1];
    secondUser.click();

    await findByText('Following');

    expect(queryByText(/You're following 2 people/i)).toBeDefined();
    expect(queryByText(/continue/i)).toBeDefined();
  });

  it('should have a functioning de/select all toggle', async () => {
    fetch.mockResponse(fakeUsersResponse);
    const {
      getByText,
      queryByText,
      findByText,
      findAllByText,
    } = renderFollowUsers();

    // select all then test following count
    const followAllSelector = await findByText(/Select all 3 people/i);

    followAllSelector.click();

    await findAllByText('Following');

    expect(queryByText('Follow')).toBeNull();
    queryByText(/You're following 3 people (everyone)/i);

    // deselect all then test following count
    const deselecAllSelector = await findByText(/Deselect all/i);

    deselecAllSelector.click();
    await findAllByText('Follow');

    expect(queryByText('Following')).toBeNull();
    getByText(/You're not following anyone/i);
  });

  it('should render a stepper', () => {
    const { queryByTestId } = renderFollowUsers();

    expect(queryByTestId('stepper')).toBeDefined();
  });

  it('should render a back button', () => {
    const { queryByTestId } = renderFollowUsers();

    expect(queryByTestId('back-button')).toBeDefined();
  });
});
