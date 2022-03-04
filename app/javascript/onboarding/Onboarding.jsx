import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { FocusTrap } from '../shared/components/focusTrap';
import { IntroSlide } from './components/IntroSlide';
import { EmailPreferencesForm } from './components/EmailPreferencesForm';
import { FollowTags } from './components/FollowTags';
import { FollowUsers } from './components/FollowUsers';
import { ProfileForm } from './components/ProfileForm';

export class Onboarding extends Component {
  constructor(props) {
    super(props);

    const url = new URL(window.location);
    const previousLocation = url.searchParams.get('referrer');

    const slides = [
      IntroSlide,
      FollowTags,
      ProfileForm,
      FollowUsers,
      EmailPreferencesForm,
    ];

    this.nextSlide = this.nextSlide.bind(this);
    this.prevSlide = this.prevSlide.bind(this);
    this.slidesCount = slides.length;

    this.state = {
      currentSlide: 0,
    };

    this.slides = slides.map((SlideComponent, index) => (
      <SlideComponent
        next={this.nextSlide}
        prev={this.prevSlide}
        slidesCount={this.slidesCount}
        currentSlideIndex={index}
        key={index}
        communityConfig={props.communityConfig}
        previousLocation={previousLocation}
      />
    ));
  }

  nextSlide() {
    const { currentSlide } = this.state;
    const nextSlide = currentSlide + 1;
    if (nextSlide < this.slides.length) {
      this.setState({
        currentSlide: nextSlide,
      });
    } else {
      // Redirect to the main feed at the end of onboarding.
      window.location.href = '/';
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

  // TODO: Update main element id to enable skip link. See issue #1153.
  render() {
    const { currentSlide } = this.state;
    const { communityConfig } = this.props;
    return (
      <main
        className="onboarding-body"
        style={
          communityConfig.communityBackground
            ? {
                backgroundImage: `url(${communityConfig.communityBackground})`,
              }
            : null
        }
      >
        <FocusTrap key={`onboarding-${currentSlide}`}>
          {this.slides[currentSlide]}
        </FocusTrap>
      </main>
    );
  }
}

Onboarding.propTypes = {
  communityConfig: PropTypes.shape({
    communityName: PropTypes.string.isRequired,
    communityBackground: PropTypes.string.isRequired,
    communityLogo: PropTypes.string.isRequired,
    communityDescription: PropTypes.string.isRequired,
  }).isRequired,
};
