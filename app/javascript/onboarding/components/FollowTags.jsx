import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import { getContentOfToken } from '../utilities';
import Navigation from './Navigation';

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
      .then((response) => response.json())
      .then((data) => {
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
        user: { last_onboarding_page: 'v2: follow tags page' },
      }),
      credentials: 'same-origin',
    });
  }

  handleClick(tag) {
    let { selectedTags } = this.state;
    if (!selectedTags.includes(tag)) {
      this.setState((prevState) => ({
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
      selectedTags.map((tag) =>
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
    ).then((_) => {
      const { next } = this.props;
      next();
    });
  }

  renderFollowCount() {
    const { selectedTags } = this.state;
    let followingStatus;
    if (selectedTags.length === 1) {
      followingStatus = `${selectedTags.length} tag selected`;
    } else {
      followingStatus = `${selectedTags.length} tags selected`;
    }

    const classStyle =
      selectedTags.length > 0
        ? 'fw-bold color-base-60 fs-base'
        : 'color-base-60 fs-base';
    return <p className={classStyle}>{followingStatus}</p>;
  }

  render() {
    const { prev, currentSlideIndex, slidesCount } = this.props;
    const { selectedTags, allTags } = this.state;
    const canSkip = selectedTags.length === 0;

    return (
      <div
        data-testid="onboarding-follow-tags"
        className="onboarding-main crayons-modal"
      >
        <div
          className="crayons-modal__box overflow-auto"
          role="dialog"
          aria-labelledby="title"
          aria-describedby="subtitle"
        >
          <Navigation
            prev={prev}
            next={this.handleComplete}
            canSkip={canSkip}
            slidesCount={slidesCount}
            currentSlideIndex={currentSlideIndex}
          />
          <div className="onboarding-content toggle-bottom">
            <header className="onboarding-content-header">
              <h1 id="title" className="title">
                What are you interested in?
              </h1>
              <h2 id="subtitle" className="subtitle">
                Follow tags to customize your feed
              </h2>
              {this.renderFollowCount()}
            </header>
            <div data-testid="onboarding-tags" className="onboarding-tags">
              {allTags.map((tag) => (
                <div
                  className={`onboarding-tags__item ${
                    selectedTags.includes(tag) &&
                    'onboarding-tags__item--selected'
                  }`}
                  style={{
                    boxShadow: selectedTags.includes(tag)
                      ? `inset 0 0 0 100px ${tag.bg_color_hex}`
                      : `inset 0 0 0 2px ${tag.bg_color_hex}`,
                    color: selectedTags.includes(tag) ? tag.text_color_hex : '',
                  }}
                >
                  <div className="onboarding-tags__item__inner">
                    #{tag.name}
                    <button
                      type="button"
                      onClick={() => this.handleClick(tag)}
                      className={`onboarding-tags__button ${
                        selectedTags.includes(tag) &&
                        'onboarding-tags__button--selected'
                      }`}
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
                        'Follow'
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
  slidesCount: PropTypes.number.isRequired,
  currentSlideIndex: PropTypes.func.isRequired,
};

export default FollowTags;
