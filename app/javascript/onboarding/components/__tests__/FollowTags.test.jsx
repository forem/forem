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

    expect(getByText(/skip for now/i)).toExist();
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

    expect(queryByTestId('stepper')).toExist();
  });

  it('should render a back button', () => {
    const { queryByTestId } = renderFollowTags();

    expect(queryByTestId('back-button')).toExist();
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

  it('should toggle the checkbox when container is clicked', async () => {
    const { container } = renderFollowTags();
    const checkbox = container.querySelector('#email_digest_periodic');

    expect(checkbox.checked).toBeFalsy();

    fireEvent.click(container.querySelector('.onboarding-email-digest'));

    expect(checkbox.checked).toBeTruthy();

    fireEvent.click(container.querySelector('.onboarding-email-digest'));

    expect(checkbox.checked).toBeFalsy();
  });

  it('should toggle the checkbox when Enter or Space key is pressed', async () => {
    const { container } = renderFollowTags();
    const checkbox = container.querySelector('#email_digest_periodic');

    expect(checkbox.checked).toBeFalsy();

    fireEvent.keyDown(container.querySelector('.onboarding-email-digest'), {
      key: 'Enter',
      code: 'Enter',
      keyCode: 13,
      charCode: 13,
    });

    expect(checkbox.checked).toBeTruthy();

    fireEvent.keyDown(container.querySelector('.onboarding-email-digest'), {
      key: ' ',
      code: 'Space',
      keyCode: 32,
      charCode: 32,
    });

    expect(checkbox.checked).toBeFalsy();
  });

  it('should prevent checkbox click event from propagating', async () => {
    const { container } = renderFollowTags();
    const checkbox = container.querySelector('#email_digest_periodic');

    let clicked = false;

    checkbox.addEventListener('click', () => {
      clicked = true;
    });

    fireEvent.click(container.querySelector('.onboarding-email-digest'));

    expect(clicked).toBeFalsy();
  });

  it('should call /onboarding/notifications API when email_digest_periodic is true', async () => {
    const { getByText, container } = renderFollowTags();

    fireEvent.click(container.querySelector('.onboarding-email-digest'));

    const skipButton = getByText(/Skip for now/i);
    fireEvent.click(skipButton);

    await waitFor(() => {
      const [lastFetchUri] = fetch.mock.calls[fetch.mock.calls.length - 1];
      expect(lastFetchUri).toEqual('/onboarding/notifications');
    });
  });

  describe('emailDigestPeriodic state initialization', () => {
    it('should initialize email_digest_periodic to true when data-default-email-optin-allowed is true', async () => {
      // Simulate setting data-default-email-optin-allowed to true
      document.body.dataset.defaultEmailOptinAllowed = 'true';

      const { container } = renderFollowTags();
      const checkbox = container.querySelector('#email_digest_periodic');

      // Assert that the checkbox is checked, indicating email_digest_periodic state is true
      expect(checkbox.checked).toBeTruthy();
    });

    it('should initialize email_digest_periodic to false when data-default-email-optin-allowed is false', async () => {
      // Simulate setting data-default-email-optin-allowed to false
      document.body.dataset.defaultEmailOptinAllowed = 'false';

      const { container } = renderFollowTags();
      const checkbox = container.querySelector('#email_digest_periodic');

      // Assert that the checkbox is not checked, indicating email_digest_periodic state is false
      expect(checkbox.checked).toBeFalsy();
    });
  });
});
