import { h } from 'preact';
import { render, waitFor } from '@testing-library/preact';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';
import { axe } from 'jest-axe';

import { IntroSlide } from '../IntroSlide';

global.fetch = fetch;

describe('IntroSlide', () => {
  const renderIntroSlide = () =>
    render(
      <IntroSlide
        next={jest.fn()}
        prev={jest.fn()}
        currentSlideIndex={0}
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

  beforeAll(() => {
    document.head.innerHTML =
      '<meta name="csrf-token" content="some-csrf-token" />';
    document.body.setAttribute('data-user', getUserData());
  });

  it('should have no a11y violations', async () => {
    const { container } = render(renderIntroSlide());
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should load the appropriate text and images', () => {
    const { getByTestId, getByText, getByAltText } = renderIntroSlide();

    expect(getByTestId('onboarding-introduction-title')).toHaveTextContent(
      /firstname lastname— welcome to Community Name!/i,
    );
    getByText('Some community description');
    expect(getByAltText('Community Name').getAttribute('src')).toEqual(
      '/x.png',
    );
  });

  it('should link to the code of conduct', () => {
    const { getByText } = renderIntroSlide();
    expect(getByText(/code of conduct/i)).toHaveAttribute('href');
    expect(getByText(/code of conduct/i).getAttribute('href')).toContain(
      '/code-of-conduct',
    );
  });

  it('should link to the terms and conditions', () => {
    const { getByText } = renderIntroSlide();
    expect(getByText(/terms and conditions/i)).toHaveAttribute('href');
    expect(getByText(/terms and conditions/i).getAttribute('href')).toContain(
      '/terms',
    );
  });

  it('should not render a stepper', () => {
    const { queryByTestId } = renderIntroSlide();
    expect(queryByTestId('stepper')).toBeNull();
  });

  it('should not render a back button', () => {
    const { queryByTestId } = renderIntroSlide();
    expect(queryByTestId('back-button')).toBeNull();
  });

  it('should enable the button if required boxes are checked', async () => {
    const { getByTestId, getByText, findByText } = renderIntroSlide();
    fetch.mockResponseOnce({});
    expect(getByText(/continue/i)).toBeDisabled();

    const codeOfConductCheckbox = getByTestId('checked-code-of-conduct');
    codeOfConductCheckbox.click();

    const termsCheckbox = getByTestId('checked-terms-and-conditions');
    termsCheckbox.click();

    const nextButton = await findByText(/continue/i);
    await waitFor(() => expect(nextButton).not.toBeDisabled());
  });
});
