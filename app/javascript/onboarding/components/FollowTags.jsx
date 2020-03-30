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
        <Navigation prev={prev} next={this.handleComplete} />
        <div className="onboarding-content">
          <header className="onboarding-content-header">
            <h1 className="title">What are you interested in?</h1>
            <h2 className="subtitle">Follow tags to customize your feed</h2>
          </header>
          <div className="onboarding-modal-scroll-container">
            <div className="onboarding-tags">
              {allTags.map(tag => (
                <div
                  className={`onboarding-tags__item ${selectedTags.includes(
                    tag,
                  ) && 'onboarding-tags__item--selected'}`}
                  style={{
                    boxShadow: selectedTags.includes(tag)
                      ? `inset 0 0 0 100px ${tag.bg_color_hex}`
                      : `inset 0 0 0 2px ${tag.bg_color_hex}`,
                    color: selectedTags.includes(tag) ? tag.text_color_hex : '',
                  }}
                >
                  <div className="onboarding-tags__item__inner">
                    #
                    {tag.name}
                    <button
                      type="button"
                      onClick={() => this.handleClick(tag)}
                      className={`onboarding-tags__button ${selectedTags.includes(
                        tag,
                      ) && 'onboarding-tags__button--selected'}`}
                      style={{
                        backgroundColor: selectedTags.includes(tag)
                          ? tag.text_color_hex
                          : tag.bg_color_hex,
                        color: selectedTags.includes(tag)
                          ? tag.bg_color_hex
                          : tag.text_color_hex,
                      }}
                    >
                      {selectedTags.includes(tag) ? (
                        <span>
                          <span className="onboarding-tags__button-default">
                            ✓ Following
                          </span>
                          <span className="onboarding-tags__button-alt">
                            Unfollow
                          </span>
                        </span>
                      ) : (
                        '+ Follow'
                      )}
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  }
}

FollowTags.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
};

export default FollowTags;
