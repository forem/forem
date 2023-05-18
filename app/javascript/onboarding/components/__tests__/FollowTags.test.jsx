import { h } from 'preact';
import { render, waitFor, fireEvent } from '@testing-library/preact';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';

import { FollowTags } from '../FollowTags';

global.fetch = fetch;

describe('FollowTags', () => {
  const renderFollowTags = () =>
    render(
      <FollowTags
        next={jest.fn()}
        prev={jest.fn()}
        currentSlideIndex={1}
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

  const fakeTagsResponse = JSON.stringify([
    {
      bg_color_hex: '#000000',
      id: 715,
      name: 'discuss',
      text_color_hex: '#ffffff',
      taggings_count: 12,
    },
    {
      bg_color_hex: '#f7df1e',
      id: 6,
      name: 'javascript',
      text_color_hex: '#000000',
      taggings_count: 0,
    },
    {
      bg_color_hex: '#2a2566',
      id: 630,
      name: 'career',
      text_color_hex: '#ffffff',
      taggings_count: 1,
    },
  ]);

  beforeAll(() => {
    document.head.innerHTML =
      '<meta name="csrf-token" content="some-csrf-token" />';
    document.body.setAttribute('data-user', getUserData());
  });

  it('should render the correct tags and counts', async () => {
    fetch.mockResponseOnce(fakeTagsResponse);
    const { findByText } = renderFollowTags();
    const javascriptTag = await findByText(/javascript/i);
    const javascriptCount = await findByText('0 posts');
    const discussTag = await findByText(/discuss/i);
    const discussCount = await findByText('12 posts');
    const careerTag = await findByText(/career/i);
    const careerCount = await findByText('1 post');

    expect(javascriptTag).toBeInTheDocument();
    expect(javascriptCount).toBeInTheDocument();
    expect(discussTag).toBeInTheDocument();
    expect(discussCount).toBeInTheDocument();
    expect(careerTag).toBeInTheDocument();
    expect(careerCount).toBeInTheDocument();
  });

  it('should render the correct navigation button on first load', () => {
    fetch.mockResponseOnce(fakeTagsResponse);
    const { getByText } = renderFollowTags();

    expect(getByText(/skip for now/i)).toBeDefined();
  });

  it('should update the status and count when you follow a tag', async () => {
    fetch.mockResponse(fakeTagsResponse);

    const { getByText, findByTestId } = renderFollowTags();

    const javascriptTag = await findByTestId(`onboarding-tag-item-6`);
    javascriptTag.click();

    await waitFor(() =>
      expect(getByText('1 tag selected')).toBeInTheDocument(),
    );
    await waitFor(() => expect(getByText(/continue/i)).toBeInTheDocument());
  });

  it('should render a stepper', () => {
    const { queryByTestId } = renderFollowTags();

    expect(queryByTestId('stepper')).toBeDefined();
  });

  it('should render a back button', () => {
    const { queryByTestId } = renderFollowTags();

    expect(queryByTestId('back-button')).toBeDefined();
  });

  it('should call handleClick when enter key is pressed', async () => {
    fetch.mockResponseOnce(fakeTagsResponse);
    const { findByTestId, getByText } = renderFollowTags();
    const javascriptTag = await findByTestId(`onboarding-tag-item-6`);

    // Simulate 'Enter' key press
    fireEvent.keyDown(javascriptTag, {
      key: 'Enter',
      code: 'Enter',
      keyCode: 13,
      charCode: 13,
    });

    await waitFor(() =>
      expect(getByText('1 tag selected')).toBeInTheDocument(),
    );
  });

  it('should call handleClick when space key is pressed', async () => {
    fetch.mockResponseOnce(fakeTagsResponse);
    const { findByTestId, getByText } = renderFollowTags();
    const javascriptTag = await findByTestId(`onboarding-tag-item-6`);

    // Simulate 'Space' key press
    fireEvent.keyDown(javascriptTag, {
      key: ' ',
      code: 'Space',
      keyCode: 32,
      charCode: 32,
    });

    await waitFor(() =>
      expect(getByText('1 tag selected')).toBeInTheDocument(),
    );
  });

  it('should call handleClick and not select the tag when any other key is pressed', async () => {
    fetch.mockResponseOnce(fakeTagsResponse);
    const { findByTestId, getByText } = renderFollowTags();
    const javascriptTag = await findByTestId(`onboarding-tag-item-6`);

    // Simulate 'A' key press
    fireEvent.keyDown(javascriptTag, { key: 'A', code: 'KeyA', charCode: 65 });

    await waitFor(() =>
      expect(getByText('0 tags selected')).toBeInTheDocument(),
    );
  });
});
