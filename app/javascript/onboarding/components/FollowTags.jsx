import { h, Component } from 'preact';
import PropTypes from 'prop-types';

import { getContentOfToken } from '../utilities';
import { Navigation } from './Navigation';

export class FollowTags extends Component {
  constructor(props) {
    super(props);

    this.handleChange = this.handleChange.bind(this);
    this.handleClick = this.handleClick.bind(this);
    this.handleComplete = this.handleComplete.bind(this);

    const emailState =
      document.body.dataset.default_email_optin_allowed === 'true';
    this.state = {
      allTags: [],
      selectedTags: [],
      email_digest_periodic: emailState,
    };
  }

  componentDidMount() {
    fetch('/onboarding/tags')
      .then((response) => response.json())
      .then((data) => {
        this.setState({ allTags: data });
      });

    const csrfToken = getContentOfToken('csrf-token');
    fetch('/onboarding', {
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

  handleContainerClick = () => {
    const checkbox = document.getElementById('email_digest_periodic');
    checkbox.checked = !checkbox.checked;

    const event = new Event('change', { bubbles: true });
    checkbox.dispatchEvent(event);

    this.setState({ email_digest_periodic: checkbox.checked });
  };

  handleContainerKeyDown = (event) => {
    if (event.key === 'Enter' || event.key === ' ') {
      this.handleContainerClick();
    }
  };

  handleCheckboxClick = (event) => {
    event.stopPropagation();
  };

  handleChange = (event) => {
    const { name, checked } = event.target;
    this.setState({ [name]: checked });
  };

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
    const { selectedTags, email_digest_periodic } = this.state;

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
    )
      .then(() => {
        if (email_digest_periodic) {
          return fetch('/onboarding/notifications', {
            method: 'PATCH',
            headers: {
              'X-CSRF-Token': csrfToken,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              notifications: {
                email_digest_periodic: this.state.email_digest_periodic,
              },
            }),
            credentials: 'same-origin',
          });
        }
        return Promise.resolve();
      })
      .then((response) => {
        if (!email_digest_periodic || response.ok) {
          const { next } = this.props;
          next();
        }
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

    return <p className="color-base-60 fs-base">{followingStatus}</p>;
  }

  render() {
    const { prev, currentSlideIndex, slidesCount } = this.props;
    const { selectedTags, allTags, email_digest_periodic } = this.state;
    const canSkip = selectedTags.length === 0;

    return (
      <div
        data-testid="onboarding-follow-tags"
        className="onboarding-main crayons-modal crayons-modal--large"
      >
        <div
          className="crayons-modal__box overflow-auto"
          role="dialog"
          aria-labelledby="title"
          aria-describedby="subtitle"
        >
          <div className="onboarding-content onboarding-content__tags toggle-bottom ">
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
              {allTags.map((tag) => {
                const selected = selectedTags.includes(tag);
                return (
                  <div
                    data-testid={`onboarding-tag-item-${tag.id}`}
                    className={`onboarding-tags__item ${
                      selected ? 'onboarding-tags__item--selected' : ''
                    }`}
                    aria-label={`Follow ${tag.name}`}
                    key={tag.id}
                    onClick={() => this.handleClick(tag)}
                    onKeyDown={(event) => {
                      // Trigger for enter (13) and space (32) keys
                      if (event.keyCode === 13 || event.keyCode === 32) {
                        this.handleClick(tag);
                      }
                    }}
                    tabIndex={0}
                    role="button"
                  >
                    <div className="onboarding-tags__item__inner">
                      <div className="onboarding-tags__item__inner__content">
                        <div className="onboarding-tags__item__inner__content-name">
                          #{tag.name}
                        </div>
                        <div className="onboarding-tags__item__inner__content-count">
                          {tag.taggings_count === 1
                            ? '1 post'
                            : `${tag.taggings_count} posts`}
                        </div>
                      </div>
                      <input
                        class="crayons-checkbox"
                        type="checkbox"
                        checked={selected}
                        tabindex="-1"
                      />
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
          <span class="onboarding-content-separator" />
          <div
            class="onboarding-email-digest"
            onClick={this.handleContainerClick}
            onKeyDown={this.handleContainerKeyDown}
            role="button"
            tabIndex="0"
          >
            <span class="onboarding-email-digest__rectangle" />
            <div class="flex items-start my-4 ml-1 mr-4">
              <form>
                <fieldset>
                  <ul>
                    <li className="checkbox-item">
                      <label htmlFor="email_digest_periodic">
                        <input
                          type="checkbox"
                          id="email_digest_periodic"
                          name="email_digest_periodic"
                          checked={email_digest_periodic}
                          onChange={this.handleChange}
                          onClick={this.handleCheckboxClick}
                          tabIndex="-1"
                        />
                      </label>
                    </li>
                  </ul>
                </fieldset>
              </form>
              <div class="flex flex-col items-start">
                <p class="crayons-subtitle-3 fw-medium">
                  Get a Periodic Digest of Top Posts
                </p>
                <p class="fs-s fw-normal lh-base color-secondary">
                  We'll email you with a curated selection of top posts based on
                  the tags you follow.
                </p>
              </div>
            </div>
          </div>
          <Navigation
            prev={prev}
            next={this.handleComplete}
            canSkip={canSkip}
            slidesCount={slidesCount}
            currentSlideIndex={currentSlideIndex}
          />
        </div>
      </div>
    );
  }
}

FollowTags.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.func.isRequired,
  slidesCount: PropTypes.number.isRequired,
  currentSlideIndex: PropTypes.number.isRequired,
};
