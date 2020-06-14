import { h } from 'preact';
import { render, waitForElement, waitFor, fireEvent } from '@testing-library/preact';
import { axe } from 'jest-axe';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';

import FollowUsers from '../FollowUsers';

global.fetch = fetch;

describe('FollowUsers', () => {
  const renderFollowUsers = () => render(
    <FollowUsers
      next={jest.fn()}
      prev={jest.fn()}
      currentSlideIndex={4}
      communityConfig={{
        communityName: 'Community Name',
        communityDescription: 'Some community description',
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

  beforeEach(async () => {
    document.head.innerHTML = '<meta name="csrf-token" content="some-csrf-token" />';
    document.body.setAttribute('data-user', getUserData());
  });

  it('should render the correct users', async () => {
    fetch.mockResponseOnce(fakeUsersResponse);
    const { findByText, findByTestId, debug } = renderFollowUsers();

    // const onboardingUsers = await findByTestId('onboarding-users');
    // debug(onboardingUsers)
    // QUESTION: why doesnt this show the inside divs with the users

    const user1 = await findByText(/Ben Halpern/i);
    const user2 = await findByText(/Krusty the Clown/i);
    const user3 = await findByText(/dev.to staff/i);

    expect(user1).toBeInTheDocument();
    expect(user2).toBeInTheDocument();
    expect(user3).toBeInTheDocument();
  });

  it('should render the correct navigation button on first load', () => {
    fetch.mockResponseOnce(fakeUsersResponse);
    const { getByText } = renderFollowUsers();
    getByText(/skip for now/i);
  });

  it('should update the navigation button text and follow status when you follow users', async () => {
    fetch.mockResponse(fakeUsersResponse);
    const { getByText, findAllByText, findByText, getByTestId, findAllByTestId, debug } = renderFollowUsers();

    const userButtons = await waitForElement(() =>
      findAllByTestId('onboarding-user-button'),
    );

    getByText(/skip for now/i);
    getByText("You're not following anyone");

    // follow the first user
    const firstUser = userButtons[0];
    firstUser.click();

    let following = await waitForElement(() =>
      findByText('Following'),
    );

    getByText("You're following 1 person");
    getByText(/continue/i);

    // follow the second user
    const secondUser = userButtons[1];
    secondUser.click();

    following = await waitForElement(() =>
      findByText('Following'),
    );

    getByText("You're following 2 people");
    getByText(/continue/i);

  });

  it('should have a functioning de/select all toggle', async () => {

  });

  it('should render a stepper', () => {
    const { getByTestId } = renderFollowUsers();
    getByTestId('stepper');
  });

});
