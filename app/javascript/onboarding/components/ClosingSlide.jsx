import { h } from 'preact';
import PropTypes from 'prop-types';

import Navigation from './Navigation';

const ClosingSlide = ({ prev, next }) => (
  <div>
    <h1>
      Congrats{' '}
      <span role="img" aria-label="tada">
        🎉
      </span>{' '}
      you&lsquo;re officially part of the DEV community!
    </h1>
    <ul>
      <li>
        Join the <a href="/welcome">Welcome Thread</a>
      </li>
      <li>
        <a href="/new">Write</a> your own DEV post
      </li>
      <li>
        <a href="/top/infinity">Read</a> some of the most popular all time posts
      </li>
      <li>
        <a href="/settings">Customize</a> your profile
      </li>
    </ul>
    <Navigation prev={prev} next={next} hideNext />
  </div>
);

ClosingSlide.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
};

export default ClosingSlide;
