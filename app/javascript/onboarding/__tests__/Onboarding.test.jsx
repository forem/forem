import { h } from 'preact';
import { render, waitForElement } from '@testing-library/preact';
import { axe } from 'jest-axe';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';

import Onboarding from '../Onboarding';
global.fetch = fetch;

// NOTE: the navigation and behaviour per component is tested in each components unit test. This file simply tests the ability to move forward and backward in a modal, and can probably be replaced by an end to end test at some point.

describe('<Onboarding />', () => {

  const renderOnboarding = () => render(
    <Onboarding
      communityConfig={{
        communityName: 'Community Name',
        communityLogo: '/x.png',
        communityBackground: '/y.jpg',
        communityDescription: "Some community description",
      }}
    />,
  )
  const getUserData = () =>
    JSON.stringify({
      followed_tag_names: ['javascript'],
      profile_image_90: 'mock_url_link',
      name: 'firstname lastname',
      username: 'username',
    });
  const fakeEmptyResponse = JSON.stringify([]);
  const { location } = window;

  beforeAll(() => {
    document.head.innerHTML = '<meta name="csrf-token" content="some-csrf-token" />';
    document.body.setAttribute('data-user', getUserData());
  });

  it('should have no a11y violations', async () => {
    const { container } = renderOnboarding();
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('should render the IntroSlide first', () => {
    const { getByTestId } = renderOnboarding();
    getByTestId('onboarding-intro-slide');
  });

  it('should allow the modal to move forward and backward a step where relevant', async () => {
    // combined back and forward into one test to avoid a long test running time
    const { getByTestId, getByText } = renderOnboarding();
    getByTestId('onboarding-intro-slide');

    fetch.mockResponseOnce({});
    const codeOfConductCheckbox = getByTestId('checked-code-of-conduct');
    codeOfConductCheckbox.click();
    const termsCheckbox = getByTestId('checked-terms-and-conditions');
    termsCheckbox.click();

    // click to next step
    const nextButton = await waitForElement(() =>
      getByText(/continue/i),
    );

    fetch.mockResponse(fakeEmptyResponse);
    nextButton.click();

    // we should be on the Follow tags step
    await waitForElement(() =>
      getByTestId('onboarding-follow-tags'),
    );

    // click a step back
    const backButton = getByTestId('back-button')
    backButton.click();

    // we should be on the Intro Slide step
    await waitForElement(() =>
      getByTestId('onboarding-intro-slide'),
    );
  });

  it("should skip the step when 'Skip for now' is clicked", async () => {
    const { getByTestId, getByText } = renderOnboarding();
    getByTestId('onboarding-intro-slide');

    fetch.mockResponseOnce({});
    const codeOfConductCheckbox = getByTestId('checked-code-of-conduct');
    codeOfConductCheckbox.click();
    const termsCheckbox = getByTestId('checked-terms-and-conditions');
    termsCheckbox.click();

    // click to next step
    const nextButton = await waitForElement(() =>
      getByText(/continue/i),
    );

    fetch.mockResponse(fakeEmptyResponse);
    nextButton.click();

    // we should be on the Follow tags step
    await waitForElement(() =>
      getByTestId('onboarding-follow-tags'),
    );

    // click on skip for now
    const skipButton = getByText(/Skip for now/i);
    skipButton.click();

    // we should be on the Profile Form step
    await waitForElement(() =>
      getByTestId('onboarding-profile-form'),
    );
  })

  it("should redirect the users to the correct steps every time", async () => {
    const { getByTestId, getByText, debug } = renderOnboarding();
    getByTestId('onboarding-intro-slide');

    fetch.mockResponseOnce({});
    const codeOfConductCheckbox = getByTestId('checked-code-of-conduct');
    codeOfConductCheckbox.click();
    const termsCheckbox = getByTestId('checked-terms-and-conditions');
    termsCheckbox.click();

    // click to next step
    const nextButton = await waitForElement(() =>
      getByText(/continue/i),
    );

    fetch.mockResponse(fakeEmptyResponse);
    nextButton.click();

    // we should be on the Follow tags step
    await waitForElement(() =>
      getByTestId('onboarding-follow-tags'),
    );

    // click on skip for now
    let skipButton = getByText(/Skip for now/i);
    skipButton.click();

    // we should be on the Profile Form step
    await waitForElement(() =>
      getByTestId('onboarding-profile-form'),
    );

    // click on skip for now
    skipButton = getByText(/Skip for now/i);
    fetch.mockResponse(fakeEmptyResponse);
    skipButton.click();

    // we should be on the Follow Users step
    await waitForElement(() =>
      getByTestId('onboarding-follow-users'),
    );

    // click on skip for now
    skipButton = getByText(/Skip for now/i);
    skipButton.click();

    // we should be on the Onboarding Email Preferences Form step
    await waitForElement(() =>
      getByTestId('onboarding-email-preferences-form'),
    );

    fetch.once({});
    // Setup: Enable window.location to be writable.
    const url = 'https://dummy.com/onboarding';
    Object.defineProperty(window, 'location', {
      value: { href: url },
      writable: true,
    });

    // click on finish
    const finishButton = getByText(/Finish/i);
    finishButton.click();

    const href = window.location.href
    expect(href).toEqual(url);

    // TODO: we should be redirected to '/'
    // await waitForElement(() => expect(href).toEqual('/'));
  });
});
