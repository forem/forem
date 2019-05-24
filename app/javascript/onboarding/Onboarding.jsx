import 'preact/devtools';
import { h, Component } from 'preact';

import WelcomeSlide from './components/WelcomeSlide';
import PersonalInfoForm from './components/PersonalInfoForm';
import EmailListTermsConditionsForm from './components/EmailListTermsConditionsForm';
import ClosingSlide from './components/ClosingSlide';

export default class Onboarding extends Component {
  constructor(props) {
    super(props);

    this.nextSlide = this.nextSlide.bind(this);
    this.prevSlide = this.prevSlide.bind(this);

    const slides = [
      WelcomeSlide,
      PersonalInfoForm,
      EmailListTermsConditionsForm,
      ClosingSlide,
    ];
    this.slides = slides.map(SlideComponent => (
      <SlideComponent next={this.nextSlide} prev={this.prevSlide} />
    ));

    this.state = {
      currentSlide: 0,
    };
  }

  nextSlide() {
    const nextSlide = this.state.currentSlide + 1;
    if (nextSlide < this.slides.length) {
      this.setState({
        currentSlide: nextSlide,
      });
    }
  }

  prevSlide() {
    const prevSlide = this.state.currentSlide - 1;
    if (prevSlide >= 0) {
      this.setState({
        currentSlide: prevSlide,
      });
    }
  }

  render() {
    return <div>{this.slides[this.state.currentSlide]}</div>;
  }
}
