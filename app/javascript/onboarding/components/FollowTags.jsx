import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import Navigation from './Navigation';
import { getContentOfToken } from '../utilities';

class FollowTags extends Component {
  constructor(props) {
    super(props);

    this.handleClick = this.handleClick.bind(this);
    this.handleComplete = this.handleComplete.bind(this);

    this.state = {
      allTags: [],
      selectedTags: [],
    };
  }

  componentDidMount() {
    fetch('/tags/onboarding')
      .then(response => response.json())
      .then(data => {
        this.setState({ allTags: data });
      });

    const csrfToken = getContentOfToken('csrf-token');
    fetch('/onboarding_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        user: { last_onboarding_page: 'follow tags page' },
      }),
      credentials: 'same-origin',
    });
  }

  handleClick(tag) {
    let { selectedTags } = this.state;
    if (!selectedTags.includes(tag)) {
      this.setState(prevState => ({
        selectedTags: [...prevState.selectedTags, tag],
      }));
    } else {
      selectedTags = [...selectedTags];
      const indexToRemove = selectedTags.indexOf(tag);
      selectedTags.splice(indexToRemove, 1);
      this.setState({
        selectedTags,
      });
    }
  }

  handleComplete() {
    const csrfToken = getContentOfToken('csrf-token');
    const { selectedTags } = this.state;

    Promise.all(
      selectedTags.map(tag =>
        fetch('/follows', {
          method: 'POST',
          headers: {
            'X-CSRF-Token': csrfToken,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            followable_type: 'Tag',
            followable_id: tag.id,
            verb: 'follow',
          }),
          credentials: 'same-origin',
        }),
      ),
    ).then(_ => {
      const { next } = this.props;
      next();
    });
  }

  render() {
    const { prev } = this.props;
    const { selectedTags, allTags } = this.state;
    return (
      <div className="onboarding-main">
        <div className="onboarding-content">
          <h2>Follow tags to customize your feed</h2>
          <div className="scroll">
            {allTags.map(tag => (
              <button
                type="button"
                onClick={() => this.handleClick(tag)}
                style={{
                  backgroundColor: tag.bg_color_hex,
                  color: tag.text_color_hex,
                }}
                className={
                  selectedTags.includes(tag) ? 'tag tag-selected' : 'tag'
                }
              >
                #
                {tag.name}
                <div className="onboarding-tag-follow-indicator">
                  {selectedTags.includes(tag) ? '✓ following ' : ''}
                </div>
              </button>
            ))}
          </div>
        </div>
        <Navigation prev={prev} next={this.handleComplete} />
      </div>
    );
  }
}

FollowTags.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
};

export default FollowTags;
