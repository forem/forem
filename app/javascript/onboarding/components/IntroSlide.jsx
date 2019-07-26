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
    const { prev } = this.props;
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
          <p>
            DEV is where programmers share ideas and help each other grow. It’s
            a global community for contributing and discovering great ideas,
            having debates, and making friends.
          </p>
          <p>A couple quick questions for you before you get started...</p>
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
};

export default IntroSlide;
