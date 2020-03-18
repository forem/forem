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
        <div className="onboarding-content about">
          <h2>About You!</h2>
          <form>
            <label htmlFor="summary">
              Tell the community about yourself! Write a quick bio about what
              you do, what you&apos;re interested in, or anything else!
              <textarea
                name="summary"
                onChange={this.handleChange}
                maxLength="120"
              />
            </label>
          </form>
        </div>
        <Navigation prev={prev} next={this.onSubmit} />
      </div>
    );
  }
}

BioForm.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
};

export default BioForm;
