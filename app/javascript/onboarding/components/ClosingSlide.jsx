import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import { updateOnboarding } from '../utilities';

class ClosingSlide extends Component {
  componentDidMount() {
    updateOnboarding('closing slide');
  }

  render() {
    const { previousLocation } = this.props;

    const previousLocationListElement = () => {
      if (
        previousLocation !== 'none' &&
        previousLocation !== null &&
        !previousLocation.startsWith('javascript')
      ) {
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
          <header className="onboarding-content-header">
            <h1 className="title">
              You&lsquo;re a part of the community!
              <span role="img" aria-label="tada">
                {' '}
                🎉
              </span>
            </h1>
            <h2 className="subtitle">What next?</h2>
          </header>

          <div className="onboarding-what-next">
            <a href="/welcome" data-no-instant>
              <p>
                <span className="whatnext-emoji" role="img" aria-label="tada">
                  😊
                </span>
                Join the Welcome Thread
              </p>
            </a>
            <a href="/new">
              <p>
                <span className="whatnext-emoji" role="img" aria-label="tada">
                  ✍️
                </span>
                Write your first DEV post
              </p>
            </a>
            <a href="/top/infinity">
              <p>
                <span className="whatnext-emoji" role="img" aria-label="tada">
                  🤓
                </span>
                Read all-time top posts
              </p>
            </a>
            <a href="/settings">
              <p>
                <span className="whatnext-emoji" role="img" aria-label="tada">
                  💅
                </span>
                Customize your profile
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
  previousLocation: PropTypes.string.isRequired,
};

export default ClosingSlide;
