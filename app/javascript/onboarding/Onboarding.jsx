import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { FocusTrap } from '../shared/components/focusTrap';
import { postReactions } from '../actionsPanel/services/reactions.js';
import { EmailPreferencesForm } from './components/EmailPreferencesForm';
import { FollowTags } from './components/FollowTags';
import { FollowUsers } from './components/FollowUsers';
import { ProfileForm } from './components/ProfileForm';

export class Onboarding extends Component {
  constructor(props) {
    super(props);

    this.recordBillboardConversion();

    const isRoot = document.body.dataset.isRootSubforem === 'true';

    const slides = isRoot ? [ProfileForm, EmailPreferencesForm] : [ProfileForm, FollowTags, FollowUsers, EmailPreferencesForm];

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
    } else if (
      localStorage &&
      localStorage.getItem('last_interacted_billboard')
    ) {
      const obj = JSON.parse(localStorage.getItem('last_interacted_billboard'));
      if (obj.path && obj.time && Date.parse(obj.time) > Date.now() - 900000) {
        window.location.href = obj.path;
      } else {
        window.location.href = '/';
      }
    } else {
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

  recordBillboardConversion() {
    if (!localStorage || !localStorage.getItem('last_interacted_billboard')) {
      return;
    }
    const dataBody = JSON.parse(
      localStorage.getItem('last_interacted_billboard'),
    );

    if (dataBody && dataBody['billboard_event']) {
      dataBody['billboard_event']['category'] = 'signup';

      const tokenMeta = document.querySelector("meta[name='csrf-token']");
      const csrfToken = tokenMeta && tokenMeta.getAttribute('content');
      window.fetch('/bb_tabulations', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': csrfToken,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(dataBody),
        credentials: 'same-origin',
      });
    }

    if (
      dataBody &&
      dataBody['billboard_event'] &&
      dataBody['billboard_event']['article_id']
    ) {
      window
        .fetch(`/api/articles/${dataBody['billboard_event']['article_id']}`, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
          },
          credentials: 'same-origin',
        })
        .then((response) => response.json())
        .then((data) => {
          if (data.id) {
            localStorage.setItem('onboarding_article', JSON.stringify(data));
            postReactions({
              reactable_type: 'Article',
              category: 'like',
              reactable_id: data.id,
            });
          }
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
          communityConfig.communityBackgroundColor &&
          communityConfig.communityBackgroundColor2
            ? {
                background: `linear-gradient(${communityConfig.communityBackgroundColor}, 
                                             ${communityConfig.communityBackgroundColor2})`,
              }
            : { top: 777 }
        }
      >
        <FocusTrap
          key={`onboarding-${currentSlide}`}
          clickOutsideDeactivates="true"
        >
          {this.slides[currentSlide]}
        </FocusTrap>
      </main>
    );
  }
}

Onboarding.propTypes = {
  communityConfig: PropTypes.shape({
    communityName: PropTypes.string.isRequired,
    communityBackgroundColor: PropTypes.string.isRequired,
    communityLogo: PropTypes.string.isRequired,
    communityDescription: PropTypes.string.isRequired,
  }).isRequired,
};
