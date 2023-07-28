import { h } from 'preact';
import { render, fireEvent } from '@testing-library/preact';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';

import { axe } from 'jest-axe';
import { i18nSupport } from '../../../__support__/i18n';
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
          communityBackgroundColor: '#FFF000',
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
      type_identifier: 'user',
    },
    {
      id: 2,
      name: 'Krusty the Clown',
      profile_image_url: 'clown.jpg',
      type_identifier: 'user',
    },
    {
      id: 3,
      name: 'dev.to staff',
      profile_image_url: 'dev.jpg',
      type_identifier: 'user',
    },
  ]);

  beforeAll(() => {
    i18nSupport();
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

  it('should follow all suggested users by default', async () => {
    fetch.mockResponseOnce(fakeUsersResponse);

    const { queryByText, findAllByLabelText } = renderFollowUsers();

    const selectedUsers = await findAllByLabelText('Following');
    expect(selectedUsers).toHaveLength(3);
    expect(queryByText(/Continue/i)).toExist();
  });

  it('should properly pluralize with small follower count', async () => {
    fetch.mockResponseOnce(
      JSON.stringify(JSON.parse(fakeUsersResponse).slice(-1)),
    );

    const { queryByText, findByText, findAllByLabelText, queryAllByLabelText } =
      renderFollowUsers();

    const selectedUsers = await findAllByLabelText('Following');
    expect(selectedUsers).toHaveLength(1);
    expect(queryByText(/Continue/i)).toExist();

    // deselect all then test following count
    const deselectAllSelector = await findByText(/Deselect all/i);

    fireEvent.click(deselectAllSelector);

    expect(queryAllByLabelText('Follow')).toHaveLength(1);
    expect(queryByText('Following')).not.toExist();
    expect(queryByText(/You're not following anyone/i)).toExist();

    // select all then test following count
    const followAllSelector = await findByText(/Select 1/i);

    fireEvent.click(followAllSelector);
    expect(queryByText(/You're following 1 person \(everyone\)/i)).toExist();
  });

  it('should update the navigation button text and follow status when you follow/unfollow users', async () => {
    fetch.mockResponse(fakeUsersResponse);

    const { queryByText, queryAllByLabelText, findAllByTestId } =
      renderFollowUsers();

    const userButtons = await findAllByTestId(
      'onboarding-user-following-status',
    );

    expect(queryAllByLabelText('Following')).toHaveLength(3);
    expect(queryByText(/You're following 3 people \(everyone\)/i)).toExist();
    expect(queryByText(/Continue/i)).toExist();

    // Unfollow the first user
    fireEvent.click(userButtons[0]);

    expect(queryAllByLabelText('Following')).toHaveLength(2);
    expect(queryByText(/You're following 2 people/i)).toExist();
    expect(queryByText(/continue/i)).toExist();

    // Unfollow the second user
    fireEvent.click(userButtons[1]);

    expect(queryAllByLabelText('Following')).toHaveLength(1);
    expect(queryByText(/You're following 1 person/i)).toExist();
    expect(queryByText(/continue/i)).toExist();

    // Unfollow the third user
    fireEvent.click(userButtons[2]);

    expect(queryByText('Following')).not.toExist();
    expect(queryByText(/You're not following anyone/i)).toExist();
    expect(queryByText(/skip for now/i)).toExist();

    // Follow the third user again
    fireEvent.click(userButtons[2]);

    expect(queryAllByLabelText('Following')).toHaveLength(1);
    expect(queryByText(/You're following 1 person/i)).toExist();
    expect(queryByText(/continue/i)).toExist();
  });

  it('should have a functioning de/select all toggle', async () => {
    fetch.mockResponse(fakeUsersResponse);
    const { queryByText, findByText, queryAllByLabelText } =
      renderFollowUsers();

    // deselect all then test following count
    const deselectAllSelector = await findByText(/Deselect all/i);

    fireEvent.click(deselectAllSelector);

    expect(queryAllByLabelText('Follow')).toHaveLength(3);
    expect(queryByText('Following')).not.toExist();
    expect(queryByText(/You're not following anyone/i)).toExist();

    // select all then test following count
    const followAllSelector = await findByText(/Select all 3/i);

    fireEvent.click(followAllSelector);

    expect(queryByText('Follow')).not.toExist();
    expect(queryAllByLabelText('Following')).toHaveLength(3);
    expect(queryByText(/You're following 3 people \(everyone\)/i)).toExist();
  });

  it('should render a stepper', () => {
    const { queryByTestId } = renderFollowUsers();

    expect(queryByTestId('stepper')).toExist();
  });

  it('should be able to continue to the next step', async () => {
    fetch.mockResponseOnce(fakeUsersResponse);

    const { queryByText, findAllByLabelText } = renderFollowUsers();

    const selectedUsers = await findAllByLabelText('Following');
    expect(selectedUsers).toHaveLength(3);

    const clickToContinue = queryByText(/Continue/i);
    fireEvent.click(clickToContinue);

    const idsToFollow = '{"users":[{"id":1},{"id":2},{"id":3}]}';
    const [uri, request] = fetch.mock.calls.slice(-1)[0];
    expect(uri).toEqual('/api/follows');
    expect(request['body']).toEqual(idsToFollow);
  });

  it('should render a back button', () => {
    const { queryByTestId } = renderFollowUsers();

    expect(queryByTestId('back-button')).toExist();
  });
});
