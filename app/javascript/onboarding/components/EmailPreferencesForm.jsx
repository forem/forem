import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { getContentOfToken, updateOnboarding } from '../utilities';
import { Navigation } from './Navigation';

/* eslint-disable camelcase */
export class EmailPreferencesForm extends Component {
  constructor(props) {
    super(props);

    this.onSubmit = this.onSubmit.bind(this);
    this.state = {
      content: '<p>Loading...</p>',
      askingToReconsiderEmail: false,
    };
  }

  componentDidMount() {
    fetch('/onboarding/newsletter')
      .then((response) => response.json())
      .then((json) => {
        this.setState({ content: json['content'] });
      });

    updateOnboarding('v2: email preferences form');
  }

  onSubmit() {
    const csrfToken = getContentOfToken('csrf-token');
    const newsletterEl = document.getElementById('email_newsletter');
    const newsletterChecked = newsletterEl ? newsletterEl.checked : false

    if (newsletterChecked) {
      fetch('/onboarding/notifications', {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': csrfToken,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ notifications: { email_newsletter: newsletterChecked } }),
        credentials: 'same-origin',
      }).then((response) => {
        if (response.ok) {
          localStorage.setItem('shouldRedirectToOnboarding', false);
          const { next } = this.props;
          next();
        }
      });
    } else if (!this.state.askingToReconsiderEmail) {
      this.setState({
        askingToReconsiderEmail: true,
      });
    }
  }

  finishWithoutEmail = () => {
    localStorage.setItem('shouldRedirectToOnboarding', false);
    const { next } = this.props;
    next();
  }

  finishWithEmail = () => {
    const csrfToken = getContentOfToken('csrf-token');
    fetch('/onboarding/notifications', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ notifications: { email_newsletter: true, email_digest_periodic: true } }),
      credentials: 'same-origin',
    }).then((response) => {
      if (response.ok) {
        localStorage.setItem('shouldRedirectToOnboarding', false);
        const { next } = this.props;
        next();
      }
    });
  }

  renderEmailReconsideration() {
    if(!this.state.askingToReconsiderEmail) {
      return '';
    }
    return (
      <div>
      <div style='position:absolute;left:0;right:0;top:0;bottom:0;background:black;opacity:0.8;z-index:99;' />
        <div className='crayons-card onboarding-inner-popover'>
          <p style='padding: 3vh 0 1.5vh;color:var(--base-60);'>
            👋 One last check
          </p>
          <h2 className="crayons-heading crayons-heading--bold">
            We Recommend Subscribing to Emails
          </h2>
          <p style='padding: 4vh 0 1.5vh;color:var(--base-60);max-width:660px;margin:auto;line-height:135%;'>
            Newsletters are a part of keeping up with the pulse of the overall DEV ecosystem.
            <span style='display:inline-block'>It's easy to unsubscribe later if it's not for you.</span>
          </p>
          <div className="align-center" style="padding: 5vh 0;">
            <button className="inline-block m-4 c-btn c-btn--ghost" style="opacity:0.8;" onClick={this.finishWithoutEmail}>No thank you</button>
            <button className="inline-block m-4 c-btn c-btn--primary" onClick={this.finishWithEmail}>Count me in</button>
          </div>
        </div>
      </div>);
  }
      

  render() {
    const { prev, slidesCount, currentSlideIndex } = this.props;
    return (
      <div
        data-testid="onboarding-email-preferences-form"
        className="onboarding-main crayons-modal crayons-modal--large"
      >
        <div
          className="crayons-modal__box"
          role="dialog"
          aria-labelledby="title"
          aria-describedby="subtitle"
        >
          <div
            className="onboarding-content email-preferences-wrapper"
            // eslint-disable-next-line react/no-danger
            dangerouslySetInnerHTML={{ __html: this.state.content }}
          />
          {this.renderEmailReconsideration()}
          <Navigation
            prev={prev}
            next={this.onSubmit}
            slidesCount={slidesCount}
            currentSlideIndex={currentSlideIndex}
          />
        </div>
      </div>
    );
  }
}

EmailPreferencesForm.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
  slidesCount: PropTypes.number.isRequired,
  currentSlideIndex: PropTypes.func.isRequired,
};

/* eslint-enable camelcase */
