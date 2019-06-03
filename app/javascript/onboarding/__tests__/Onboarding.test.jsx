import { h, render as preactRender } from 'preact';
// import render from 'preact-render-to-json';
import { shallow, deep } from 'preact-render-spy';
// import { JSDOM } from 'jsdom';
import Onboarding from '../Onboarding';

describe('<Onboarding />', () => {
  it('should move to the next slide upon clicking the next button', () => {
    const onboardingSlides = deep(<Onboarding />);
    onboardingSlides.find('.next-button').simulate('click');
    expect(onboardingSlides.state().currentSlide).toBe(1);
  });

  it('should move to the previous slide upon clicking the back button', () => {
    const onboardingSlides = deep(<Onboarding />);
    onboardingSlides.setState({ currentSlide: 1 });
    onboardingSlides.find('.back-button').simulate('click');
    expect(onboardingSlides.state().currentSlide).toBe(0);
  });

  it('previous slide button should not move backwards past zero', () => {
    const onboardingSlides = deep(<Onboarding />);
    onboardingSlides.find('.back-button').simulate('click');
    expect(onboardingSlides.state().currentSlide).toBe(0);
  });

  it('next slide button should not move past the number of slides', () => {
    const onboardingSlides = deep(<Onboarding />);
    const numberOfSlides = onboardingSlides.slides - 1;
    onboardingSlides.setState({ currentSlide: numberOfSlides });
    onboardingSlides.find('.next-button').simulate('click');
    expect(onboardingSlides.state().currentSlide).toBe(numberOfSlides);
  });
});