import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import Navigation from './Navigation';
import { getContentOfToken } from '../utilities';

class IntroSlide extends Component {
  constructor(props) {
    super(props);

    this.onSubmit = this.onSubmit.bind(this);
  }

  componentDidMount() {
    const csrfToken = getContentOfToken('csrf-token');
    fetch('/onboarding_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ user: { last_onboarding_page: 'intro slide' } }),
      credentials: 'same-origin',
    });
  }

  onSubmit() {
    const { next } = this.props;
    next();
  }

  render() {
    const { prev, variant } = this.props;
    let onboardingBody = (
      <div>
        <p>
          DEV is where programmers share ideas and help each other grow. 🤓
        </p>
        <p>
          Ask questions, leave helpful comments, encourage others, and have fun! 🙌
        </p>
        <p>
          A few <strong>quick questions</strong> for you before you get started...
        </p>
      </div>
    )

    if (variant === '1') {
      onboardingBody = <div style={{textAlign: 'center'}}>
          <img src='https://media.giphy.com/media/ICOgUNjpvO0PC/giphy.gif' alt='hello cat' style={{borderRadius: '8px', height: '220px'}} />
          <br/><strong><em>Let's get started...</em></strong>
        </div>
    } else if ( variant === '2') {
      onboardingBody = <div style={{textAlign: 'center'}}>
        <img src='https://media.giphy.com/media/ICOgUNjpvO0PC/giphy.gif' alt='hello cat' style={{borderRadius: '8px', height: '140px'}} />
        <p>We have a few quick questions to fill out your profile</p>
        <p>
          <strong><em>Let's get started...</em></strong>
        </p>
      </div>
    } else if ( variant === '3') {
      onboardingBody = <div style={{textAlign: 'center', fontSize: '0.9em'}}>
        <img src='https://media.giphy.com/media/aWRWTF27ilPzy/giphy.gif' alt='hello' style={{borderRadius: '8px', height: '140px'}} />
        <p>The more you get involved in community, the better developer you will be.</p>
        <p>
          <strong><em>Let's get started...</em></strong>
        </p>
      </div>
    } else if ( variant === '4') {
      onboardingBody = <div style={{textAlign: 'center', fontSize: '1.1em'}}>
        <img src='https://media.giphy.com/media/aWRWTF27ilPzy/giphy.gif' alt='hello' style={{borderRadius: '8px', height: '140px'}} />
        <p>You just made a great choice for your dev career.</p>
        <p>
          <strong><em>Let's get started...</em></strong>
        </p>
      </div>
    }
    return (
      <div className="onboarding-main">
        <div className="onboarding-content">
          <h1>
            <span>Welcome to the </span>
            <img
              src="/assets/purple-dev-logo.png"
              className="sticker-logo"
              alt="DEV"
            />
            <span>community!</span>
          </h1>
          {onboardingBody}
        </div>
        <Navigation prev={prev} next={this.onSubmit} hidePrev />
      </div>
    );
  }
}

// const IntroSlide = ({ prev, next }) => (

// );

IntroSlide.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
  variant: PropTypes.string.isRequired,
};

export default IntroSlide;
