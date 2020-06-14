import { h } from 'preact';
import { render, waitForElement, waitFor, fireEvent } from '@testing-library/preact';
import { axe } from 'jest-axe';
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

  beforeEach(async () => {
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

  it('should update the button text when you click on follow', async () => {
    fetch.mockResponse(fakeTagsResponse);
    const { getByText, findAllByText, findByText, getByTestId, debug } = renderFollowTags();

    const followButtons = await waitForElement(() =>
      findAllByText('Follow'),
    );

    // click on the first follow button
    const button = followButtons[0];
    debug(button);
    button.click();
    // fireEvent.click(button); //thought the alternate may work

    // it should change to Following
    const followedButton = await waitForElement(() => {
      findByText('Following'),
    });

    // FIX: this test should ahve showed the Follow button
  });

  xit('should update the count of tags selected', async () => {
  });

  xit('should update the text on the forward button', async () => {
    fetch.mockResponse(fakeTagsResponse);
    const { getByText, findAllByText, findByText, getByTestId, debug } = renderFollowTags();
    findByText(/skip for now/);

    // TODO: after the first follow it should update the text to continue
  });

  it('should render a stepper', () => {
    const { getByTestId } = renderFollowTags();
    getByTestId('stepper');
  });

});
