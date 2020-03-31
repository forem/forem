import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import Navigation from './Navigation';
import { getContentOfToken, updateOnboarding } from '../utilities';

class BioForm extends Component {
  constructor(props) {
    super(props);

    this.handleChange = this.handleChange.bind(this);
    this.onSubmit = this.onSubmit.bind(this);

    this.state = {
      summary: '',
    };
  }

  componentDidMount() {
    updateOnboarding('bio form');
  }

  onSubmit() {
    const csrfToken = getContentOfToken('csrf-token');
    const { summary } = this.state;
    fetch('/onboarding_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ user: { summary } }),
      credentials: 'same-origin',
    }).then(response => {
      if (response.ok) {
        const { next } = this.props;
        next();
      }
    });
  }

  handleChange(e) {
    const { value } = e.target;

    this.setState({
      summary: value,
    });
  }

  render() {
    const { prev } = this.props;
    return (
      <div className="onboarding-main">
        <Navigation prev={prev} next={this.onSubmit} />
        <div className="onboarding-content about">
          <header className="onboarding-content-header">
            <h1 className="title">Introduce yourself</h1>
            <h2 className="subtitle">
              Tell the community about yourself. Write a quick bio about what
              you do, what you&apos;re interested in, or anything else.
            </h2>
          </header>
          <form>
            <label htmlFor="summary">
              Bio
              <textarea
                name="summary"
                placeholder="Tell us about yourself"
                onChange={this.handleChange}
                maxLength="120"
              />
            </label>
          </form>
        </div>
      </div>
    );
  }
}

BioForm.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
};

export default BioForm;
