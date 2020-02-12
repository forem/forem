import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import { updateOnboarding } from '../utilities';

class ClosingSlide extends Component {
  componentDidMount() {
    updateOnboarding('closing slide');
  }

  whatsNextLinks() {
    const properties = [
      { href: '/welcome', text: 'Join the Welcome Thread', emoji: '😊' },
      { href: '/new', text: 'Write your first DEV post', emoji: '✍️' },
      { href: '/top/infinity', text: 'Read all-time top posts', emoji: '🤓' },
      { href: '/settings', text: 'Customize your profile', emoji: '💅' },
    ];
    return properties;
  };

  render() {
    const { previousLocation, variant } = this.props;

    const previousLocationListElement = () => {
      if (variant === '6' || variant === '8') {
        return (
          <div className="onboarding-previous-location">
            <span role="img" aria-label="sparkle">
              ✨
            </span>
            {' '}
            <em>Challenge: Leave 3 constructive comments today</em>
            {' '}
            <span role="img" aria-label="sparkle">
              ✨
            </span>
          </div>
        );
      }
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

    const nextStepLinks = () => {
      if (variant === '7' || variant === '8') {
        return (
          <div className="onboarding-what-next">
            <a
              href="/welcome"
              data-no-instant
              style={{
                width: '100%',
                textAlign: 'center',
                maxWidth: '500px',
                margin: 'auto',
                paddingTop: '50px',
                fontSize: '1.4em',
              }}
            >
              <div style={{ maxWidth: '80%', margin: 'auto' }}>
                Join the Welcome Thread
              </div>
              <p className="whatnext-emoji">
                <span role="img" aria-label="tada">
                  😊
                </span>
              </p>
            </a>
          </div>
        );
      }
      if (variant === '9') {
        return (
          <div className="onboarding-what-next">
            <a
              href="/welcome"
              data-no-instant
              style={{
                width: 'calc(100% - 4px)',
                textAlign: 'center',
                maxWidth: '500px',
                height: '190px',
                margin: 'auto',
                padding: '0px 0px',
                borderRadius: '5px',
                paddingTop: 'calc(10px + 2vw)',
                fontSize: '1.4em',
                boxShadow: '3px 3px 0px #5779b9',
              }}
            >
              <div style={{ maxWidth: '90%', margin: 'auto' }}>
                Join the Welcome Thread
                <span
                  role="img"
                  aria-label="tada"
                  style={{ marginLeft: '0.3em' }}
                >
                  🚀
                </span>
              </div>
              <br />
              <p style={{ fontSize: '0.7em', maxWidth: '88%', margin: 'auto' }}>
                Challenge: Leave 3 constructive comments
              </p>
              <p
                style={{
                  fontSize: '0.50em',
                  maxWidth: '66%',
                  margin: 'auto',
                  marginTop: '1.5em',
                }}
              >
                <em>
                  Ask questions, offer encouragement and participate in
                  discussion threads.
                </em>
              </p>
            </a>
          </div>
        );
      }
      return ( 
        <div className="onboarding-what-next">
          {this.whatsNext().map((element, index) => {
            <a key={ index } href={ element.href } data-no-instant={(index === 0) ? true : null }>
              { element.text }
              <p className="whatnext-emoji">
              <span role="img" aria-label="tada">
                { element.emoji }
              </span>
              </p>
            </a>  
          })}
        </div>);
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
          {nextStepLinks()}
          {previousLocationListElement()}
        </div>
      </div>
    );
  }
}

ClosingSlide.propTypes = {
  previousLocation: PropTypes.string.isRequired,
  variant: PropTypes.string.isRequired,
};

export default ClosingSlide;
