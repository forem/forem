import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import he from 'he';
import { getContentOfToken } from '../utilities';
import { locale } from '../../utilities/locale';
import { Navigation } from './Navigation';

function groupFollowsByType(array) {
  return array.reduce((returning, item) => {
    const type = item.type_identifier
    returning[type] = (returning[type] || []).concat(item);
    return returning;
  }, {})
}

function groupFollowIdsByType(array) {
  return array.reduce((returning, item) => {
    const type = item.type_identifier
    returning[type] = (returning[type] || []).concat({id: item.id});
    return returning;
  }, {})
}

export class FollowUsers extends Component {
  constructor(props) {
    super(props);

    this.handleClick = this.handleClick.bind(this);
    this.handleComplete = this.handleComplete.bind(this);

    this.state = {
      follows: [],
      selectedFollows: [],
    };
  }

  componentDidMount() {
    fetch('/onboarding/users_and_organizations', {
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      credentials: 'same-origin',
    })
      .then((response) => response.json())
      .then((data) => {
        this.setState({
          selectedFollows: data,
          follows: data,
        });
      });

    const csrfToken = getContentOfToken('csrf-token');
    fetch('/onboarding', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        user: { last_onboarding_page: 'v2: follow users page' },
      }),
      credentials: 'same-origin',
    });
  }

  handleComplete() {
    const csrfToken = getContentOfToken('csrf-token');
    const { selectedFollows } = this.state;
    const { next } = this.props;
    const idsGroupedByType = groupFollowIdsByType(selectedFollows);

    fetch('/api/follows', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        users: idsGroupedByType["user"],
        organizations: idsGroupedByType["organization"] }),
      credentials: 'same-origin',
    });

    next();
  }

  handleSelectAll() {
    const { selectedFollows, follows } = this.state;
    if (selectedFollows.length === follows.length) {
      this.setState({
        selectedFollows: [],
      });
    } else {
      this.setState({
        selectedFollows: follows,
      });
    }
  }

  handleClick(follow) {
    let { selectedFollows } = this.state;

    if (!selectedFollows.includes(follow)) {
      this.setState((prevState) => ({
        selectedFollows: [...prevState.selectedFollows, follow],
      }));
    } else {
      selectedFollows = [...selectedFollows];
      const indexToRemove = selectedFollows.indexOf(follow);
      selectedFollows.splice(indexToRemove, 1);
      this.setState({
        selectedFollows,
      });
    }
  }

  renderFollowCount() {
    const { follows, selectedFollows } = this.state;

    let followingStatus;
    if (selectedFollows.length === 0) {
      followingStatus = locale("core.not_following");
    } else if (selectedFollows.length === follows.length) {
      followingStatus = `${locale("core.following_everyone")  }`;
    } else {
      const groups = groupFollowsByType(selectedFollows);
      let together = []
      for (const type in groups) {
        const counted = locale(`core.counted_${type}`, {count: groups[type].length});
        together = together.concat(counted)
      }

      const anded_together = together.join(` ${locale("core.and")} `);
      followingStatus = `${locale("core.you_are_following")} ${anded_together}`;
    }

    const klassName =
      selectedFollows.length > 0
        ? 'fw-bold color-base-60 inline-block fs-base'
        : 'color-base-60 inline-block fs-base';

    return <p className={klassName}>{followingStatus} -</p>;
  }

  renderFollowToggle() {
    const { follows, selectedFollows } = this.state;
    let followText = '';

    if (selectedFollows.length !== follows.length) {
      if (follows.length === 1) {
        followText = `Select ${follows.length}`;
      } else {
        followText = `Select all ${follows.length}`;
      }
    } else {
      followText = 'Deselect all';
    }

    return (
      <button
        type="button"
        class="crayons-btn crayons-btn--ghost-brand -ml-2"
        onClick={() => this.handleSelectAll()}
      >
        {followText}
      </button>
    );
  }

  render() {
    const { follows, selectedFollows } = this.state;
    const { prev, slidesCount, currentSlideIndex } = this.props;
    const canSkip = selectedFollows.length === 0;

    return (
      <div
        data-testid="onboarding-follow-users"
        className="onboarding-main crayons-modal crayons-modal--large"
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
                Suggested people to follow
              </h1>
              <h2 id="subtitle" className="subtitle">
                Let&apos;s review a few things first
              </h2>
              <div className="onboarding-selection-status">
                {this.renderFollowCount()}
                {this.renderFollowToggle()}
              </div>
            </header>

            <fieldset data-testid="onboarding-users">
              {follows.map((follow) => {
                const selected = selectedFollows.includes(follow);

                return (
                  <div
                    key={`${follow.id}-${follow.type_identifier}`}
                    data-testid="onboarding-user-button"
                    className={`user content-row ${
                      selected ? 'selected' : 'unselected'
                    }`}
                  >
                    <figure className="user-avatar-container">
                      <img
                        className="user-avatar"
                        src={follow.profile_image_url}
                        alt=""
                        loading="lazy"
                      />
                    </figure>
                    <div className="user-info">
                      <h4 className="user-name">{follow.name}</h4>
                      <p className="user-summary">
                        {he.unescape(follow.summary || '')}
                      </p>
                    </div>
                    <label
                      className={`relative user-following-status crayons-btn ${
                        selected ? 'color-primary' : 'crayons-btn--outlined'
                      }`}
                    >
                      <input
                        aria-label={`Follow ${follow.name}`}
                        type="checkbox"
                        checked={selected}
                        className="absolute opacity-0 absolute top-0 bottom-0 right-0 left-0"
                        onClick={() => this.handleClick(follow)}
                        data-testid="onboarding-user-following-status"
                      />
                      {selected ? 'Following' : 'Follow'}
                    </label>
                  </div>
                );
              })}
            </fieldset>
          </div>
        </div>
      </div>
    );
  }
}

FollowUsers.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.string.isRequired,
  slidesCount: PropTypes.number.isRequired,
  currentSlideIndex: PropTypes.func.isRequired,
};
