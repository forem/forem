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
      content: '<p>Loading...</p>'
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
