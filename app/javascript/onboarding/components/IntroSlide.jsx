import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import Navigation from './Navigation';
import { updateOnboarding } from '../utilities';

class IntroSlide extends Component {
  constructor(props) {
    super(props);

    this.onSubmit = this.onSubmit.bind(this);
  }

  componentDidMount() {
    updateOnboarding('intro slide');
  }

  onSubmit() {
    const { next } = this.props;
    next();
  }

  render() {
    const { prev } = this.props;

    return (
      <div className="onboarding-main introduction">
        <div className="onboarding-content">
          <figure>
            <img
              src="/assets/purple-dev-logo.png"
              className="sticker-logo"
              alt="DEV"
            />
          </figure>
          <h1 className="introduction-title">Welcome to DEV!</h1>
          <h2 className="introduction-subtitle">
            DEV is where programmers share ideas and help each other grow.
          </h2>
        </div>
        <Navigation prev={prev} next={this.onSubmit} hidePrev />
      </div>
    );
  }
}

IntroSlide.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
};

export default IntroSlide;
