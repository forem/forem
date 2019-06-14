import 'preact/devtools';
import { h, Component } from 'preact';

import WelcomeSlide from './components/WelcomeSlide';
import PersonalInfoForm from './components/PersonalInfoForm';
import EmailListTermsConditionsForm from './components/EmailListTermsConditionsForm';
import ClosingSlide from './components/ClosingSlide';
import FollowTags from './components/FollowTags';
import FollowUsers from './components/FollowUsers';

export default class Onboarding extends Component {
  constructor(props) {
    super(props);

    this.nextSlide = this.nextSlide.bind(this);
    this.prevSlide = this.prevSlide.bind(this);

    const slides = [
      WelcomeSlide,
      PersonalInfoForm,
      EmailListTermsConditionsForm,
      FollowTags,
      FollowUsers,
      ClosingSlide,
    ];

    this.slides = slides.map(SlideComponent => (
      <SlideComponent next={this.nextSlide} prev={this.prevSlide} />
    ));

    this.state = {
      currentSlide: 2,
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
    return (
      <div className="onboarding-body">
        <div className="onboarding-content">
          <img
            src="https://res.cloudinary.com/practicaldev/image/fetch/s--iiubRINO--/c_imagga_scale,f_auto,fl_progressive,q_auto,w_300/https://practicaldev-herokuapp-com.freetls.fastly.net/assets/sloan.png"
            className="sloan-img"
            alt="Sloan, the sloth mascot"
          />
          {this.slides[this.state.currentSlide]}
        </div>
      </div>
    );
  }
}
