import { h } from 'preact';
import { deep } from 'preact-render-spy';
import fetch from 'jest-fetch-mock';
import { axe, toHaveNoViolations } from 'jest-axe';

import Onboarding from '../Onboarding';
import ProfileForm from '../components/ProfileForm';
import FollowTags from '../components/FollowTags';
import FollowUsers from '../components/FollowUsers';

global.fetch = fetch;

// Corresponds to the order of slides declared in the Onboarding component.
const slides = [
  'IntroSlide',
  'FollowTags',
  'ProfileForm',
  'FollowUsers',
  'EmailPreferencesForm',
];

function flushPromises() {
  return new Promise((resolve) => setImmediate(resolve));
}

function initializeSlides(currentSlide, userData = null, mockData = null) {
  document.body.setAttribute('data-user', userData);
  const onboardingSlides = deep(
    <Onboarding
      communityConfig={{
        communityName: 'Test',
        communityDescription: "Wouldn't you like to knoww..",
      }}
    />,
  );

  if (mockData) {
    fetch.once(mockData);
  }

  onboardingSlides.setState({ currentSlide });

  return onboardingSlides;
}

function expectStepperToRender(onboardingSlides, activeDotCount) {
  // We do not show the stepper on the IntroSlide.
  const stepperDotCount = slides.length - 1;

  expect(onboardingSlides.find('.stepper').exists()).toEqual(true);
  expect(onboardingSlides.find('.dot').length).toBe(stepperDotCount);
  expect(onboardingSlides.find('.active').length).toBe(activeDotCount);
}

describe('<Onboarding />', () => {
  beforeAll(() => {
    expect.extend(toHaveNoViolations);
  });
  beforeEach(() => {
    fetch.resetMocks();
  });

  // Use this to fetch mock response data before trying to render the `followTags` component.
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

  // Use this to fetch mock response data before trying to render the `followUsers` component.
  const fakeUsersResponse = JSON.stringify([
    {
      id: 1,
      name: 'Ben Halpern',
      profile_image_url: 'ben.jpg',
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
  const getUserData = () =>
    JSON.stringify({
      followed_tag_names: ['javascript'],
      profile_image_90: 'mock_url_link',
      name: 'firstname lastname',
      username: 'username',
    });

  describe('IntroSlide', () => {
    const slideIndex = slides.indexOf('IntroSlide');
    let onboardingSlides;
    const codeOfConductCheckEvent = {
      target: {
        value: 'checked_code_of_conduct',
        name: 'checked_code_of_conduct',
      },
    };
    const termsAndConditionsCheckEvent = {
      target: {
        value: 'checked_terms_and_conditions',
        name: 'checked_terms_and_conditions',
      },
    };

    const updateCodeOfConduct = () => {
      onboardingSlides
        .find('#checked_code_of_conduct')
        .simulate('change', codeOfConductCheckEvent);
    };
    const updateTermsAndConditions = () => {
      onboardingSlides
        .find('#checked_terms_and_conditions')
        .simulate('change', termsAndConditionsCheckEvent);
    };

    beforeEach(() => {
      onboardingSlides = initializeSlides(slideIndex, getUserData());
    });

    test('renders properly', () => {
      expect(onboardingSlides).toMatchSnapshot();
    });

    test('it does not render a stepper', () => {
      expect(onboardingSlides.find('.stepper').length).toBe(0);
    });

    test('should advance if required boxes are checked', async () => {
      fetch.once({});
      expect(onboardingSlides.state().currentSlide).toBe(slideIndex);

      updateCodeOfConduct();
      updateTermsAndConditions();

      onboardingSlides.find('.next-button').simulate('click');

      // Fetch the fakeTagsResponse before trying to render the next slide (followTags).
      fetch.once(fakeTagsResponse);
      await flushPromises();
      expect(onboardingSlides.state().currentSlide).toBe(slideIndex + 1);
    });

    test('should not have basic a11y violations', async () => {
      const results = await axe(onboardingSlides.toString());

      expect(results).toHaveNoViolations();
    });
  });

  describe('FollowTags', () => {
    let onboardingSlides;
    const slideIndex = slides.indexOf('FollowTags');

    beforeEach(async () => {
      onboardingSlides = initializeSlides(
        slideIndex,
        getUserData(),
        fakeTagsResponse,
      );
      await flushPromises();
    });

    test('renders properly', () => {
      expect(onboardingSlides).toMatchSnapshot();
    });

    test('renders a stepper', () => {
      expectStepperToRender(onboardingSlides, slideIndex);
    });

    test('should render three tags', async () => {
      expect(onboardingSlides.find('.onboarding-tags__item').length).toBe(3);
    });

    test('should allow a user to add a tag and advance', async () => {
      fetch.once({});
      expect(onboardingSlides.find('.next-button').text()).toContain(
        'Skip for now',
      );

      const firstButton = onboardingSlides
        .find('.onboarding-tags__button')
        .first();

      firstButton.simulate('click');
      const followTags = onboardingSlides.find(<FollowTags />);
      expect(followTags.state('selectedTags').length).toBe(1);

      expect(onboardingSlides.find('.next-button').text()).toContain(
        'Continue',
      );

      onboardingSlides.find('.next-button').simulate('click');
      fetch.once(fakeUsersResponse);
      await flushPromises();
      expect(onboardingSlides.state().currentSlide).toBe(slideIndex + 1);
    });

    it('should step backward', () => {
      onboardingSlides.find('.back-button').simulate('click');
      expect(onboardingSlides.state().currentSlide).toBe(slideIndex - 1);
    });
  });

  describe('ProfileForm', () => {
    let onboardingSlides;
    const slideIndex = slides.indexOf('ProfileForm');
    const meta = document.createElement('meta');

    meta.setAttribute('name', 'csrf-token');
    document.body.appendChild(meta);

    beforeEach(() => {
      onboardingSlides = initializeSlides(slideIndex, getUserData());
    });

    test('renders properly', () => {
      expect(onboardingSlides).toMatchSnapshot();
    });

    test('renders a stepper', () => {
      expectStepperToRender(onboardingSlides, slideIndex);
    });

    test('should allow user to fill forms and advance', async () => {
      fetch.once({});
      const summaryEvent = { target: { value: 'my bio', name: 'summary' } };
      const locationEvent = {
        target: { value: 'my location', name: 'location' },
      };
      const titleEvent = {
        target: { value: 'my title', name: 'employment_title' },
      };
      const employerEvent = {
        target: { value: 'my employer name', name: 'employer_name' },
      };

      expect(onboardingSlides.find('.next-button').text()).toContain(
        'Skip for now',
      );

      onboardingSlides.find('textarea').simulate('change', summaryEvent);
      onboardingSlides.find('#location').simulate('change', locationEvent);
      onboardingSlides.find('#employment_title').simulate('change', titleEvent);
      onboardingSlides.find('#employer_name').simulate('change', employerEvent);
      const profileForm = onboardingSlides.find(<ProfileForm />);
      expect(profileForm.state().formValues.summary).toBe(
        summaryEvent.target.value,
      );
      expect(profileForm.state().formValues.location).toBe(
        locationEvent.target.value,
      );
      expect(profileForm.state().formValues.employment_title).toBe(
        titleEvent.target.value,
      );
      expect(profileForm.state().formValues.employer_name).toBe(
        employerEvent.target.value,
      );

      expect(onboardingSlides.find('.next-button').text()).toContain(
        'Continue',
      );

      profileForm.find('.next-button').simulate('click');
      fetch.once(fakeTagsResponse);
      await flushPromises();
      expect(onboardingSlides.state().currentSlide).toBe(slideIndex + 1);
    });

    it('should step backward', () => {
      // Fetch the fakeTagsResponse before trying to render the previous slide (followTags).
      fetch.once(fakeTagsResponse);
      onboardingSlides.find('.back-button').simulate('click');
      expect(onboardingSlides.state().currentSlide).toBe(slideIndex - 1);
    });
  });

  describe('FollowUsers', () => {
    let onboardingSlides;
    const slideIndex = slides.indexOf('FollowUsers');

    beforeEach(async () => {
      onboardingSlides = initializeSlides(
        slideIndex,
        getUserData(),
        fakeUsersResponse,
      );
      await flushPromises();
    });

    test('renders properly', () => {
      expect(onboardingSlides).toMatchSnapshot();
    });

    test('renders a stepper', () => {
      expectStepperToRender(onboardingSlides, slideIndex);
    });

    test('should render three users', async () => {
      expect(onboardingSlides.find('.user').length).toBe(3);
    });

    test('should allow a user to select and advance', async () => {
      fetch.once({});

      expect(onboardingSlides.find('.next-button').text()).toContain(
        'Skip for now',
      );

      onboardingSlides.find('.user').first().simulate('click');
      expect(onboardingSlides.find('p').last().text()).toBe(
        "You're following 1 person",
      );
      onboardingSlides.find('.user').last().simulate('click');
      expect(onboardingSlides.find('p').last().text()).toBe(
        "You're following 2 people",
      );

      expect(onboardingSlides.find('.next-button').text()).toContain(
        'Continue',
      );

      const followUsers = onboardingSlides.find(<FollowUsers />);
      expect(followUsers.state('selectedUsers').length).toBe(2);
      onboardingSlides.find('.next-button').simulate('click');
      await flushPromises();
      expect(onboardingSlides.state().currentSlide).toBe(slideIndex + 1);
    });

    test('should have a functioning select-all toggle', async () => {
      fetch.once({});

      expect(onboardingSlides.find('button').last().text()).toBe(
        'Select all 3 people',
      );
      onboardingSlides.find('button').last().simulate('click');
      expect(onboardingSlides.find('button').last().text()).toBe(
        'Deselect all',
      );
      const followUsers = onboardingSlides.find(<FollowUsers />);
      expect(followUsers.state('selectedUsers').length).toBe(3);
    });

    it('should step backward', async () => {
      onboardingSlides.find('.back-button').simulate('click');
      await flushPromises();
      expect(onboardingSlides.state().currentSlide).toBe(slideIndex - 1);
    });
  });

  describe('EmailPreferencesForm', () => {
    let onboardingSlides;
    const { location } = window;
    const slideIndex = slides.indexOf('EmailPreferencesForm');

    beforeEach(() => {
      onboardingSlides = initializeSlides(slideIndex, getUserData());
    });

    afterEach(() => {
      window.location = location;
    });

    test('renders properly', () => {
      expect(onboardingSlides).toMatchSnapshot();
    });

    test('renders a stepper', () => {
      expectStepperToRender(onboardingSlides, slideIndex);
    });

    test('should redirect user when finished', async () => {
      fetch.once({});

      // Setup: Enable window.location to be writable.
      const url = 'https://dummy.com/onboarding';
      Object.defineProperty(window, 'location', {
        value: { href: url },
        writable: true,
      });

      expect(window.location.href).toBe(url);
      onboardingSlides.find('.next-button').simulate('click');
      await flushPromises();
      // No longer advance slide.
      expect(onboardingSlides.state().currentSlide).toBe(slideIndex);
      expect(window.location.href).toBe('/');
    });

    it('should step backward', () => {
      onboardingSlides.find('.back-button').simulate('click');
      expect(onboardingSlides.state().currentSlide).toBe(slideIndex - 1);
    });
  });
});
