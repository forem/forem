import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import { getContentOfToken, userData, updateOnboarding } from '../utilities';
import Navigation from './Navigation';

/* eslint-disable camelcase */
class IntroSlide extends Component {
  constructor(props) {
    super(props);

    this.handleChange = this.handleChange.bind(this);
    this.onSubmit = this.onSubmit.bind(this);
    this.user = userData();

    this.state = {
      checked_code_of_conduct: false,
      checked_terms_and_conditions: false,
      text: null,
    };
  }

  componentDidMount() {
    updateOnboarding('v2: intro, code of conduct, terms & conditions');
  }

  onSubmit() {
    const { next } = this.props;
    const csrfToken = getContentOfToken('csrf-token');

    fetch('/onboarding_checkbox_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ user: this.state }),
      credentials: 'same-origin',
    }).then((response) => {
      if (response.ok) {
        localStorage.setItem('shouldRedirectToOnboarding', false);
        next();
      }
    });
  }

  handleChange(event) {
    const { name } = event.target;
    this.setState((currentState) => ({
      [name]: !currentState[name],
    }));
  }

  handleShowText(event, id) {
    event.preventDefault();
    this.setState({ text: document.getElementById(id).innerHTML });
  }

  isButtonDisabled() {
    const {
      checked_code_of_conduct,
      checked_terms_and_conditions,
    } = this.state;

    return !checked_code_of_conduct || !checked_terms_and_conditions;
  }

  render() {
    const {
      slidesCount,
      currentSlideIndex,
      prev,
      communityConfig,
    } = this.props;
    const {
      checked_code_of_conduct,
      checked_terms_and_conditions,
      text,
    } = this.state;

    if (text) {
      return (
        <div className="onboarding-main crayons-modal crayons-modal--m">
          <div className="crayons-modal__box overflow-auto">
            <div className="onboarding-content terms-and-conditions-wrapper">
              <button
                type="button"
                onClick={() => this.setState({ text: null })}
              >
                Back
              </button>
              <div
                className="terms-and-conditions-content"
                /* eslint-disable react/no-danger */
                dangerouslySetInnerHTML={{ __html: text }}
                /* eslint-enable react/no-danger */
              />
            </div>
          </div>
        </div>
      );
    }

    return (
      <div
        data-testid="onboarding-intro-slide"
        className="onboarding-main introduction crayons-modal crayons-modal--m"
      >
        <div
          className="crayons-modal__box overflow-auto"
          role="dialog"
          aria-labelledby="title"
          aria-describedby="subtitle"
        >
          <div className="onboarding-content">
            <figure>
              <img
                src={communityConfig.communityLogo}
                className="sticker-logo"
                alt={communityConfig.communityName}
              />
            </figure>
            <h1
              id="title"
              data-testid="onboarding-introduction-title"
              className="introduction-title"
            >
              {this.user.name}
              &mdash; welcome to {communityConfig.communityName}!
            </h1>
            <h2 id="subtitle" className="introduction-subtitle">
              {communityConfig.communityDescription}
            </h2>
          </div>

          <div className="checkbox-form-wrapper">
            <form className="checkbox-form">
              <fieldset>
                <ul>
                  <li className="checkbox-item">
                    <label
                      data-testid="checked-code-of-conduct"
                      htmlFor="checked_code_of_conduct"
                      className="lh-base py-1"
                    >
                      <input
                        type="checkbox"
                        id="checked_code_of_conduct"
                        name="checked_code_of_conduct"
                        checked={checked_code_of_conduct}
                        onChange={this.handleChange}
                      />
                      You agree to uphold our&nbsp;
                      <a
                        href="/code-of-conduct"
                        data-no-instant
                        onClick={(e) => this.handleShowText(e, 'coc')}
                      >
                        Code of Conduct
                      </a>
                      .
                    </label>
                  </li>

                  <li className="checkbox-item">
                    <label
                      data-testid="checked-terms-and-conditions"
                      htmlFor="checked_terms_and_conditions"
                      className="lh-base py-1"
                    >
                      <input
                        type="checkbox"
                        id="checked_terms_and_conditions"
                        name="checked_terms_and_conditions"
                        checked={checked_terms_and_conditions}
                        onChange={this.handleChange}
                      />
                      You agree to our&nbsp;
                      <a
                        href="/terms"
                        data-no-instant
                        onClick={(e) => this.handleShowText(e, 'terms')}
                      >
                        Terms and Conditions
                      </a>
                      .
                    </label>
                  </li>
                </ul>
              </fieldset>
            </form>
            <Navigation
              disabled={this.isButtonDisabled()}
              className="intro-slide"
              prev={prev}
              slidesCount={slidesCount}
              currentSlideIndex={currentSlideIndex}
              next={this.onSubmit}
              hidePrev
            />
          </div>
        </div>
      </div>
    );
  }
}

IntroSlide.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.func.isRequired,
  slidesCount: PropTypes.number.isRequired,
  currentSlideIndex: PropTypes.func.isRequired,
  communityConfig: PropTypes.shape({
    communityLogo: PropTypes.string.isRequired,
    communityName: PropTypes.string.isRequired,
    communityDescription: PropTypes.string.isRequired,
  }).isRequired,
};

export default IntroSlide;

/* eslint-enable camelcase */
