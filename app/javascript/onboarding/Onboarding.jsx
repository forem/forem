import 'preact/devtools';
import { h, Component } from 'preact';

import IntroSlide from './components/IntroSlide';
import PersonalInfoForm from './components/PersonalInfoForm';
import EmailListTermsConditionsForm from './components/EmailListTermsConditionsForm';
import ClosingSlide from './components/ClosingSlide';
import FollowTags from './components/FollowTags';
import FollowUsers from './components/FollowUsers';
import BioForm from './components/BioForm';

// Current Onboarding Variants
// 0) Original intro slide: three explainer paragraphs, left adjusted.
// 1) Modified intro slide: Cat gif, let's get started.
// 2) Modified intro slide: Cat gif, We have a few quick questions to fill out your profile
// 3) Modified intro slide: Skull gif, The more you get involved in community, the better developer you will be.
// 4) Modified intro slide: Skull gif, You just made a great choice for your dev career
// 5) No intro slide.
// 6) Last slide challenge: Leave three constructive comments today
// 7) Last slide: Only display cue for welcome thread
// 8) Last slide: Only display cue for welcome thread, and also the leave three constructive comments challenge
// 9) Last slide: Only display cue for welcome thread, display challenge right in link body

export default class Onboarding extends Component {
  constructor(props) {
    super(props);

    const url = new URL(window.location);
    const previousLocation = url.searchParams.get('referrer');
    let variant = '0';
    if (url.searchParams.get('variant') || window.currentUser) {
      variant =
        url.searchParams.get('variant') ||
        window.currentUser.onboarding_variant_version ||
        '0';
    }

    this.nextSlide = this.nextSlide.bind(this);
    this.prevSlide = this.prevSlide.bind(this);

    let slides = [
      IntroSlide,
      EmailListTermsConditionsForm,
      BioForm,
      PersonalInfoForm,
      FollowTags,
      FollowUsers,
      ClosingSlide,
    ];

    if (variant === '5') {
      slides = [
        EmailListTermsConditionsForm,
        BioForm,
        PersonalInfoForm,
        FollowTags,
        FollowUsers,
        ClosingSlide,
      ];
    }

    this.slides = slides.map(SlideComponent => (
      <SlideComponent
        next={this.nextSlide}
        prev={this.prevSlide}
        previousLocation={previousLocation}
        variant={variant}
      />
    ));

    this.state = {
      currentSlide: 4,
    };
  }

  nextSlide() {
    const { currentSlide } = this.state;
    const nextSlide = currentSlide + 1;
    if (nextSlide < this.slides.length) {
      this.setState({
        currentSlide: nextSlide,
      });
    }
  }

  prevSlide() {
    const { currentSlide } = this.state;
    const prevSlide = currentSlide - 1;
    if (prevSlide >= 0) {
      this.setState({
        currentSlide: prevSlide,
      });
    }
  }

  render() {
    const { currentSlide } = this.state;
    return <main className="onboarding-body">{this.slides[currentSlide]}</main>;
  }
}
