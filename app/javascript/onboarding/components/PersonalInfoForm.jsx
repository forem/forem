import { h, Component } from 'preact';

import Navigation from './Navigation';
import { jsonToForm, getContentOfToken } from '../utilities';

export default class extends Component {
  constructor(props) {
    super(props);

    this.handleChange = this.handleChange.bind(this);
    this.onSubmit = this.onSubmit.bind(this);

    this.state = {
      summary: '',
      location: '',
      employment_title: '',
      employer_name: '',
    };
  }

  handleChange() {
    const { name, value } = event.target;

    this.setState({
      [name]: value,
    });
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
        console.log(response.json().then(data => console.log(data)));
        this.props.next();
      }
    });
  }

  render() {
    return (
      <div>
        <form>
          <label htmlFor="summary">
            Tell the community about yourself! Write a quick bio about what you
            do, what you're interested in, or anything else!
          </label>
          <textarea
            name="summary"
            onChange={this.handleChange}
            maxLength="120"
          />
          <label htmlFor="location">Where are you located?</label>
          <input
            type="text"
            name="location"
            onChange={this.handleChange}
            maxLength="60"
          />
          <label htmlFor="employment_title">What is your title?</label>
          <input
            type="text"
            name="employment_title"
            onChange={this.handleChange}
            maxLength="60"
          />
          <label htmlFor="employer_name">Where do you work?</label>
          <input
            type="text"
            name="employer_name"
            onChange={this.handleChange}
            maxLength="60"
          />
        </form>
        <Navigation prev={this.props.prev} next={this.onSubmit} />
      </div>
    );
  }
}
