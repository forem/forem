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
          <a className="onboarding-previous-location" href={previousLocation}>
            <div>Or go back to the page you were on before you signed up</div>
            <code>{previousLocation}</code>
          </a>
        );
      }
      return null;
    };

    return (
      <div className="onboarding-main">
        <div className="onboarding-content">
          <h1>
            You&lsquo;re part of the community!
            <span role="img" aria-label="tada">
              {' '}
              🎉
            </span>
          </h1>
          <h2 style={{ textAlign: 'center' }}>What next?</h2>
          <div className="onboarding-what-next">
            <a href="/welcome" data-no-instant>
              Join the Welcome Thread
              <p className="whatnext-emoji">
                <span role="img" aria-label="tada">
                  😊
                </span>
              </p>
            </a>
            <a href="/new">
              Write your first DEV post
              <p className="whatnext-emoji">
                <span role="img" aria-label="tada">
                  ✍️
                </span>
              </p>
            </a>
            <a href="/top/infinity">
              Read all-time top posts
              <p className="whatnext-emoji">
                <span role="img" aria-label="tada">
                  🤓
                </span>
              </p>
            </a>
            <a href="/settings">
              Customize your profile
              <p className="whatnext-emoji">
                <span role="img" aria-label="tada">
                  💅
                </span>
              </p>
            </a>
          </div>
          {previousLocationListElement()}
        </div>
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
