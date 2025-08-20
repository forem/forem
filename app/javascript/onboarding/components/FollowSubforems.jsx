import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { getContentOfToken } from '../utilities';
import { Navigation } from './Navigation';

export class FollowSubforems extends Component {
  constructor(props) {
    super(props);

    this.handleClick = this.handleClick.bind(this);
    this.handleComplete = this.handleComplete.bind(this);

    this.state = {
      allSubforems: [],
      selectedSubforems: [],
      loading: true,
      originalSubforemId: null,
    };
  }

  componentDidMount() {
    // Get the original subforem from localStorage
    const originalSubforemId = localStorage.getItem('signup_subforem_id');
    
    this.fetchSubforems(originalSubforemId);
    
    const csrfToken = getContentOfToken('csrf-token');
    fetch('/onboarding', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        user: { last_onboarding_page: 'v2: follow subforems page' },
      }),
      credentials: 'same-origin',
    });
  }

  async fetchSubforems(originalSubforemId) {
    try {
      const response = await fetch('/api/subforems', {
        headers: {
          Accept: 'application/json',
          'Content-Type': 'application/json',
        },
        credentials: 'same-origin',
      });

      if (response.ok) {
        const subforems = await response.json();
        
        // Sort subforems: original subforem first, then by domain
        const sortedSubforems = subforems.sort((a, b) => {
          if (originalSubforemId && a.id.toString() === originalSubforemId) return -1;
          if (originalSubforemId && b.id.toString() === originalSubforemId) return 1;
          return a.domain.localeCompare(b.domain);
        });

        // Pre-select the original subforem if it exists
        const selectedSubforems = originalSubforemId 
          ? sortedSubforems.filter(s => s.id.toString() === originalSubforemId)
          : [];

        this.setState({
          allSubforems: sortedSubforems,
          selectedSubforems,
          originalSubforemId,
          loading: false,
        });
      } else {
        throw new Error('Failed to fetch subforems');
      }
    } catch (error) {
      console.error('Error fetching subforems:', error);
      this.setState({ loading: false });
    }
  }

  handleClick(subforem) {
    let { selectedSubforems } = this.state;
    if (!selectedSubforems.includes(subforem)) {
      this.setState((prevState) => ({
        selectedSubforems: [...prevState.selectedSubforems, subforem],
      }));
    } else {
      selectedSubforems = [...selectedSubforems];
      const indexToRemove = selectedSubforems.indexOf(subforem);
      selectedSubforems.splice(indexToRemove, 1);
      this.setState({
        selectedSubforems,
      });
    }
  }

  async handleComplete() {
    const csrfToken = getContentOfToken('csrf-token');
    const { selectedSubforems } = this.state;

    try {
      // Follow selected subforems
      const followPromises = selectedSubforems.map(subforem =>
        fetch('/follows', {
          method: 'POST',
          headers: {
            'X-CSRF-Token': csrfToken,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            followable_type: 'Subforem',
            followable_id: subforem.id,
          }),
          credentials: 'same-origin',
        })
      );

      await Promise.all(followPromises);
    } catch (error) {
      console.error('Error following subforems:', error);
    }

    // Clear the stored subforem ID
    localStorage.removeItem('signup_subforem_id');
    
    this.props.next();
  }

  renderFollowCount() {
    const { selectedSubforems } = this.state;
    const count = selectedSubforems.length;
    
    if (count === 0) {
      return (
        <div className="subtitle">
          Follow subforems to customize your network
        </div>
      );
    }
    
    return (
      <div className="subtitle">
        Following {count} {count === 1 ? 'subforem' : 'subforems'}
      </div>
    );
  }

  render() {
    const { prev, currentSlideIndex, slidesCount } = this.props;
    const { selectedSubforems, allSubforems, loading, originalSubforemId } = this.state;

    // Show the same layout structure whether loading or not
    // Filter out the root subforem from the list
    const subforemsToShow = loading ? [] : allSubforems.filter(subforem => !subforem.root);

    return (
      <div
        data-testid="onboarding-follow-subforems"
        className="onboarding-main crayons-modal crayons-modal--large"
      >
        <div
          className="crayons-modal__box overflow-auto"
          role="dialog"
          aria-labelledby="title"
          aria-describedby="subtitle"
        >
          <div className="onboarding-content onboarding-content__subforems">
            <header className="onboarding-content-header">
              <h1 id="title" className="title">
                What communities interest you?
              </h1>
              <h2 id="subtitle" className="subtitle">
                {this.renderFollowCount()}
              </h2>
              {originalSubforemId && (
                <div className="py-2 fs-xs color-base-70" style="line-height: 125% !important">
                  <em>
                    The subforem you joined from is highlighted below. You can follow additional communities to customize your feed.
                  </em>
                </div>
              )}
            </header>
            <div data-testid="onboarding-subforems" className="onboarding-subforems-grid">
              {subforemsToShow.length > 0 ? (
                subforemsToShow.map((subforem) => {
                  const selected = selectedSubforems.includes(subforem);
                  const isOriginal = originalSubforemId && subforem.id.toString() === originalSubforemId;
                  
                  return (
                    <div
                      data-testid={`onboarding-subforem-item-${subforem.id}`}
                      className={`onboarding-subforems__item ${
                        selected ? 'onboarding-subforems__item--selected' : ''
                      } ${isOriginal ? 'onboarding-subforems__item--original' : ''}`}
                      aria-label={`Follow ${subforem.name}`}
                      key={subforem.id}
                      onClick={() => this.handleClick(subforem)}
                      onKeyDown={(event) => {
                        // Trigger for enter (13) and space (32) keys
                        if (event.keyCode === 13 || event.keyCode === 32) {
                          this.handleClick(subforem);
                        }
                      }}
                      tabIndex={0}
                      role="button"
                    >
                      <div className="onboarding-subforems__item__inner">
                        <div className="onboarding-subforems__item__logo">
                          {subforem.logo_image_url ? (
                            <img 
                              src={subforem.logo_image_url} 
                              alt={`${subforem.name} logo`}
                              className="onboarding-subforems__item__logo-img"
                            />
                          ) : (
                            <div className="onboarding-subforems__item__logo-placeholder">
                              {subforem.name.charAt(0).toUpperCase()}
                            </div>
                          )}
                        </div>
                        <div className="onboarding-subforems__item__content">
                          <div className="onboarding-subforems__item__name">
                            {subforem.name}
                          </div>
                          <div className="onboarding-subforems__item__description">
                            {subforem.description || 'Join this community to connect with like-minded people.'}
                          </div>
                        </div>
                        <input
                          className="crayons-checkbox"
                          type="checkbox"
                          checked={selected}
                          tabIndex="-1"
                        />
                      </div>
                    </div>
                  );
                })
              ) : (
                // Show empty state with placeholder items when loading or no subforems
                Array.from({ length: 6 }, (_, index) => (
                  <div 
                    key={`placeholder-${index}`} 
                    className="onboarding-subforems__item onboarding-subforems__item--placeholder" 
                    tabIndex={0} 
                    role="button"
                  >
                    <div className="onboarding-subforems__item__inner">
                                              <div className="onboarding-subforems__item__logo">
                          <div className="onboarding-subforems__item__logo-placeholder onboarding-subforems__item__logo-placeholder--loading">
                            <div className="onboarding-subforems__item__logo-placeholder-shimmer" />
                          </div>
                        </div>
                        <div className="onboarding-subforems__item__content">
                          <div className="onboarding-subforems__item__name onboarding-subforems__item__name--loading">
                            <div className="onboarding-subforems__item__name-shimmer" />
                          </div>
                          <div className="onboarding-subforems__item__description onboarding-subforems__item__description--loading">
                            <div className="onboarding-subforems__item__description-shimmer" />
                          </div>
                        </div>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
          <Navigation
            prev={prev}
            next={this.handleComplete}
            slidesCount={slidesCount}
            currentSlideIndex={currentSlideIndex}
            nextText="Continue"
            showSkip={false}
          />
        </div>
      </div>
    );
  }
}

FollowSubforems.propTypes = {
  prev: PropTypes.func.isRequired,
  next: PropTypes.func.isRequired,
  slidesCount: PropTypes.number.isRequired,
  currentSlideIndex: PropTypes.number.isRequired,
};
