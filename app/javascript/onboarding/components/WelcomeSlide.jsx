import { h } from 'preact';
import PropTypes from 'prop-types';

import Navigation from './Navigation';

const IntroSlide = ({ prev, next }) => (
  <div>
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
      DEV is where programmers share ideas and help each other grow. It’s a
      global community for contributing and discovering great ideas, having
      debates, and making friends.
    </p>
    <p>A couple quick questions for you before you get started...</p>
    <Navigation prev={prev} next={next} hidePrev />
  </div>
);

IntroSlide.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
};

export default IntroSlide;
