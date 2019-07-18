import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import Navigation from './Navigation';
import { getContentOfToken } from '../utilities';

class ClosingSlide extends Component {
  componentDidMount() {
    const csrfToken = getContentOfToken('csrf-token');
    fetch('/onboarding_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ user: { last_onboarding_page: 'closing slide' } }),
      credentials: 'same-origin',
    });
  }

  render() {
    const { previousLocation, prev, next } = this.props;

    const previousLocationListElement = () => {
      if (previousLocation !== 'none' && previousLocation !== null) {
        return (
          <li>
            <a href={previousLocation}>Go back to before onboarding</a>
          </li>
        );
      }
      return null;
    };

    return (
      <div className="onboarding-main">
        <div className="onboarding-content">
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
              <a href="/top/infinity">Read</a> some of the most popular all time
              posts
            </li>
            <li>
              <a href="/settings">Customize</a> your profile
            </li>
            {previousLocationListElement()}
          </ul>
        </div>
        <Navigation prev={prev} next={next} hideNext />
      </div>
    );
  }
}

ClosingSlide.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
  previousLocation: PropTypes.string.isRequired,
};

export default ClosingSlide;
