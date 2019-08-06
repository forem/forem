import { h } from 'preact';
import { deep } from 'preact-render-spy';
import fetch from 'jest-fetch-mock';

import Onboarding from '../Onboarding';
import BioForm from '../components/BioForm';
import PersonalInfoForm from '../components/PersonalInfoForm';
import EmailTermsConditionsForm from '../components/EmailListTermsConditionsForm';
import FollowTags from '../components/FollowTags';
import FollowUsers from '../components/FollowUsers';

global.fetch = fetch;

function flushPromises() {
  return new Promise(resolve => setImmediate(resolve));
}

describe('<Onboarding />', () => {
  beforeEach(() => {
    fetch.resetMocks();
  });

  const fakeTagResponse = JSON.stringify([
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

  const fakeUsersToFollowResponse = JSON.stringify([
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

  const dataUser = JSON.stringify({
    followed_tag_names: ['javascript'],
  });

  describe('IntroSlide', () => {
    let onboardingSlides;
    beforeEach(() => {
      document.body.setAttribute('data-user', null);
      onboardingSlides = deep(<Onboarding />);
    });

    test('renders properly', () => {
      expect(onboardingSlides).toMatchSnapshot();
    });

    test('should move to the next slide upon clicking the next button', () => {
      onboardingSlides.find('.next-button').simulate('click');
      expect(onboardingSlides.state().currentSlide).toBe(1);
    });
  });

  describe('EmailTermsConditionsForm', () => {
    let onboardingSlides;
    beforeEach(() => {
      document.body.setAttribute('data-user', dataUser);
      onboardingSlides = deep(<Onboarding />);
      onboardingSlides.setState({ currentSlide: 1 });
    });

    test('renders properly', () => {
      expect(onboardingSlides).toMatchSnapshot();
    });

    test('should not move if code of conduct is not agreed to', () => {
      onboardingSlides.find('.next-button').simulate('click');
      expect(onboardingSlides.state().currentSlide).toBe(1);
    });

    test('should not move if terms and conditions are not met', () => {
      const event = {
        target: {
          value: 'checked_code_of_conduct',
          name: 'checked_code_of_conduct',
        },
      };
      onboardingSlides
        .find('#checked_code_of_conduct')
        .simulate('change', event);
      onboardingSlides.find('.next-button').simulate('click');
      expect(onboardingSlides.state().currentSlide).toBe(1);
    });

    test('should move to the next slide if code of conduct and terms and conditions are met', async () => {
      fetch.once({});
      onboardingSlides.find('#checked_code_of_conduct').simulate('change', {
        target: {
          value: 'checked_code_of_conduct',
          name: 'checked_code_of_conduct',
        },
      });

      onboardingSlides
        .find('#checked_terms_and_conditions')
        .simulate('change', {
          target: {
            value: 'checked_terms_and_conditions',
            name: 'checked_terms_and_conditions',
          },
        });

      const emailTerms = onboardingSlides.find(<EmailTermsConditionsForm />);
      expect(emailTerms.state('checked_code_of_conduct')).toBe(true);
      onboardingSlides.find('.next-button').simulate('click');
      await flushPromises();
      expect(onboardingSlides.state().currentSlide).toBe(2);
    });

    it('should move to the previous slide upon clicking the back button', () => {
      onboardingSlides.find('.back-button').simulate('click');
      expect(onboardingSlides.state().currentSlide).toBe(0);
    });
  });

  describe('BioForm', () => {
    let onboardingSlides;
    const meta = document.createElement('meta');
    meta.setAttribute('name', 'csrf-token');
    document.body.appendChild(meta);

    beforeEach(() => {
      onboardingSlides = deep(<Onboarding />);
      onboardingSlides.setState({ currentSlide: 2 });
      document.body.setAttribute('data-user', dataUser);
    });

    test('renders properly', () => {
      expect(onboardingSlides).toMatchSnapshot();
    });

    it('should move to the previous slide upon clicking the back button', () => {
      onboardingSlides.find('.back-button').simulate('click');
      expect(onboardingSlides.state().currentSlide).toBe(1);
    });

    test('forms can be filled and submitted', async () => {
      fetch.once({});
      const bioForm = onboardingSlides.find(<BioForm />);
      const event = { target: { value: 'my bio', name: 'summary' } };
      onboardingSlides.find('textarea').simulate('change', event);
      expect(bioForm.state('summary')).toBe('my bio');
      bioForm.find('.next-button').simulate('click');
      await flushPromises();
      expect(onboardingSlides.state().currentSlide).toBe(3);
    });
  });

  describe('PersonalInformationForm', () => {
    let onboardingSlides;
    const meta = document.createElement('meta');
    meta.setAttribute('name', 'csrf-token');
    document.body.appendChild(meta);

    beforeEach(() => {
      onboardingSlides = deep(<Onboarding />);
      onboardingSlides.setState({ currentSlide: 3 });
      document.body.setAttribute('data-user', dataUser);
    });

    test('renders properly', () => {
      expect(onboardingSlides).toMatchSnapshot();
    });

    it('should move to the previous slide upon clicking the back button', () => {
      onboardingSlides.find('.back-button').simulate('click');
      expect(onboardingSlides.state().currentSlide).toBe(2);
    });

    test('forms can be filled and submitted', async () => {
      fetch.once({});
      const personalInfoForm = onboardingSlides.find(<PersonalInfoForm />);
      const locationEvent = {
        target: { value: 'my location', name: 'location' },
      };
      onboardingSlides.find('#location').simulate('change', locationEvent);

      const titleEvent = {
        target: { value: 'my title', name: 'employment_title' },
      };
      onboardingSlides.find('#employment_title').simulate('change', titleEvent);

      const employerEvent = {
        target: { value: 'my employer name', name: 'employer_name' },
      };
      onboardingSlides.find('#employer_name').simulate('change', employerEvent);

      expect(personalInfoForm.state('location')).toBe('my location');
      expect(personalInfoForm.state('employment_title')).toBe('my title');
      expect(personalInfoForm.state('employer_name')).toBe('my employer name');

      personalInfoForm.find('.next-button').simulate('click');
      fetch.once(fakeTagResponse);
      await flushPromises();
      expect(onboardingSlides.state().currentSlide).toBe(4);
    });
  });

  describe('FollowTags', () => {
    let onboardingSlides;
    beforeEach(async () => {
      document.body.setAttribute('data-user', dataUser);
      onboardingSlides = deep(<Onboarding />);
      fetch.once(fakeTagResponse);
      onboardingSlides.setState({ currentSlide: 4 });
      await flushPromises();
    });

    test('renders properly', () => {
      expect(onboardingSlides).toMatchSnapshot();
    });

    test('it should render three tags', async () => {
      expect(onboardingSlides.find('.tag').length).toBe(3);
    });

    test('adding a tag and submitting works', async () => {
      fetch.once({});
      const followTags = onboardingSlides.find(<FollowTags />);
      onboardingSlides
        .find('.tag')
        .first()
        .simulate('click');
      expect(followTags.state('selectedTags').length).toBe(1);
      onboardingSlides.find('.next-button').simulate('click');
      fetch.once(fakeUsersToFollowResponse);
      await flushPromises();
      expect(onboardingSlides.state().currentSlide).toBe(5);
    });

    it('should move to the previous slide upon clicking the back button', () => {
      onboardingSlides.find('.back-button').simulate('click');
      expect(onboardingSlides.state().currentSlide).toBe(3);
    });
  });

  describe('FollowUsers', () => {
    let onboardingSlides;
    beforeEach(async () => {
      document.body.setAttribute('data-user', dataUser);
      onboardingSlides = deep(<Onboarding />);
      fetch.once(fakeUsersToFollowResponse);
      onboardingSlides.setState({ currentSlide: 5 });
      await flushPromises();
    });

    test('renders properly', () => {
      expect(onboardingSlides).toMatchSnapshot();
    });

    test('it should render three users', async () => {
      expect(onboardingSlides.find('.user').length).toBe(3);
    });

    test('adding a user and submitting works', async () => {
      fetch.once({});
      const followUsers = onboardingSlides.find(<FollowUsers />);
      onboardingSlides
        .find('.user')
        .first()
        .simulate('click');
      expect(followUsers.state('selectedUsers').length).toBe(2);
      onboardingSlides.find('.next-button').simulate('click');
      await flushPromises();
      expect(onboardingSlides.state().currentSlide).toBe(6);
    });

    it('should move to the previous slide upon clicking the back button', async () => {
      fetch.once(fakeTagResponse);
      onboardingSlides.find('.back-button').simulate('click');
      await flushPromises();
      expect(onboardingSlides.state().currentSlide).toBe(4);
    });
  });

  describe('CloseSlide', () => {
    let onboardingSlides;
    beforeEach(() => {
      document.body.setAttribute('data-user', null);
      onboardingSlides = deep(<Onboarding />);
      onboardingSlides.setState({ currentSlide: 6 });
    });

    test('renders properly', () => {
      expect(onboardingSlides).toMatchSnapshot();
    });
  });
});
