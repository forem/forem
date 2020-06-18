import { h } from 'preact';
import { render, waitForElement } from '@testing-library/preact';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';

import FollowTags from '../FollowTags';

global.fetch = fetch;

describe('FollowTags', () => {
  const renderFollowTags = () => render(
    <FollowTags
      next={jest.fn()}
      prev={jest.fn()}
      currentSlideIndex={1}
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

  const fakeTagsResponse = JSON.stringify([
    {
      bg_color_hex: '#000000',
      id: 715,
      name: 'discuss',
      text_color_hex: '#ffffff',
    },
    {
      bg_color_hex: '#f7df1e',
      id: 6,
      name: 'javascript',
      text_color_hex: '#000000',
    },
    {
      bg_color_hex: '#2a2566',
      id: 630,
      name: 'career',
      text_color_hex: '#ffffff',
    },
  ]);

  beforeAll(() => {
    document.head.innerHTML = '<meta name="csrf-token" content="some-csrf-token" />';
    document.body.setAttribute('data-user', getUserData());
  });

  it('should render the correct tags', async () => {
    fetch.mockResponseOnce(fakeTagsResponse);
    const { findByText } = renderFollowTags();
    const javascriptTag = await findByText(/javascript/i);
    const discussTag = await findByText(/discuss/i);
    const careerTag = await findByText(/career/i);

    expect(javascriptTag).toBeInTheDocument();
    expect(discussTag).toBeInTheDocument();
    expect(careerTag).toBeInTheDocument();
  });

  it('should render the correct navigation button on first load', () => {
    fetch.mockResponseOnce(fakeTagsResponse);
    const { getByText } = renderFollowTags();
    getByText(/skip for now/i);
  });

  it('should update the navigation button text, follow status and count when you follow a tag', async () => {
    fetch.mockResponse(fakeTagsResponse);
    const { getByText, findByText, findAllByText, getByTestId } = renderFollowTags();

    const followButtons = await waitForElement(() =>
      findAllByText('Follow'),
    );
    findByText(/skip for now/);

    // click on the first follow button
    const button = followButtons[0];
    button.click();

    // it should change to Following and update the count
    await waitForElement(() =>
      findByText(/Following/i),
    );
    getByText(/1 tag selected/i);
    getByText(/continue/i);
  });

  it('should render a stepper', () => {
    const { getByTestId } = renderFollowTags();
    getByTestId('stepper');
  });

  it('should render a back button', () => {
    const { getByTestId } = renderFollowTags();
    getByTestId('back-button');
  });
});
