import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import Navigation from './Navigation';
import { getContentOfToken } from '../utilities';

class BioForm extends Component {
  constructor(props) {
    super(props);

    this.handleChange = this.handleChange.bind(this);
    this.onSubmit = this.onSubmit.bind(this);

    this.state = {
      summary: '', // eslint-disable-line no-unused-state
    };
  }

  onSubmit() {
    const csrfToken = getContentOfToken('csrf-token');

    fetch('/onboarding_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ user: this.state }),
      credentials: 'same-origin',
    }).then(response => {
      if (response.ok) {
        this.props.next();
      }
    });
  }

  handleChange(e) {
    const { name, value } = e.target;

    this.setState({
      [name]: value,
    });
  }

  render() {
    return (
      <div className="about">
        <h1>About You!</h1>
        <form>
          <label htmlFor="summary">
            Tell the community about yourself! Write a quick bio about what you
            do, what you're interested in, or anything else!
            <textarea
              name="summary"
              onChange={this.handleChange}
              maxLength="120"
            />
          </label>
        </form>
        <Navigation prev={this.props.prev} next={this.onSubmit} />
      </div>
    );
  }
}

BioForm.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
};

export default BioForm;
