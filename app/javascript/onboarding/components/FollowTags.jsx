import { h, Component } from 'preact';

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
    fetch('/api/tags/onboarding')
      .then(response => response.json())
      .then(data => {
        this.setState({ allTags: data });
      })
      .catch(error => {
        console.log(error);
      });
  }

  handleClick(tag) {
    if (!this.state.selectedTags.includes(tag)) {
      this.setState(state => ({
        selectedTags: [...state.selectedTags, tag],
      }));
    } else {
      const selectedTags = [...this.state.selectedTags];
      const indexToRemove = selectedTags.indexOf(tag);
      selectedTags.splice(indexToRemove, 1);
      this.setState({
        selectedTags,
      });
    }
  }

  handleComplete() {
    const csrfToken = getContentOfToken('csrf-token');
    this.state.selectedTags.forEach(tag => {
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
      }).catch(error => {
        console.log(error);
      });
    });
    this.props.next();
  }

  render() {
    return (
      <div>
        <h2>Follow some tags!</h2>
        {this.state.allTags.map(tag => (
          <button
            onClick={() => this.handleClick(tag)}
            style={{
              backgroundColor: tag.bg_color_hex,
              color: tag.text_color_hex,
            }}
            className="tag"
          >
            #
            {tag.name}
          </button>
        ))}
        <Navigation prev={this.props.prev} next={this.handleComplete} />
      </div>
    );
  }
}

export default FollowTags;
