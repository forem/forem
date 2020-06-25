import { h } from 'preact';
import { render, waitForElement } from '@testing-library/preact';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';

import FollowUsers from '../FollowUsers';
import { axe } from 'jest-axe';

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
    const { getByText } = renderFollowUsers();
    getByText(/skip for now/i);
  });

  it('should update the navigation button text and follow status when you follow users', async () => {
    fetch.mockResponse(fakeUsersResponse);
    const { getByText, findByText, findAllByTestId } = renderFollowUsers();

    const userButtons = await waitForElement(() =>
      findAllByTestId('onboarding-user-button'),
    );

    getByText(/skip for now/i);
    getByText("You're not following anyone");

    // follow the first user
    const firstUser = userButtons[0];
    firstUser.click();

    await waitForElement(() => findByText('Following'));

    getByText("You're following 1 person");
    getByText(/continue/i);

    // follow the second user
    const secondUser = userButtons[1];
    secondUser.click();

    await waitForElement(() => findByText('Following'));

    getByText("You're following 2 people");
    getByText(/continue/i);
  });

  it('should have a functioning de/select all toggle', async () => {
    fetch.mockResponse(fakeUsersResponse);
    const { getByText, queryByText, queryAllByText } = renderFollowUsers();

    // select all then test following count
    const followAllSelector = await waitForElement(() =>
      getByText(/Select all 3 people/i),
    );

    followAllSelector.click();

    await waitForElement(() => queryAllByText('Following'));

    expect(queryByText('Follow')).toBeNull();
    getByText("You're following 3 people (everyone)");

    // deselect all then test following count
    const deselecAllSelector = await waitForElement(() =>
      getByText(/Deselect all/i),
    );

    deselecAllSelector.click();
    await waitForElement(() => queryAllByText('Follow'));

    expect(queryByText('Following')).toBeNull();
    getByText(/You're not following anyone/i);
  });

  it('should render a stepper', () => {
    const { getByTestId } = renderFollowUsers();
    getByTestId('stepper');
  });

  it('should render a back button', () => {
    const { getByTestId } = renderFollowUsers();
    getByTestId('back-button');
  });
});
