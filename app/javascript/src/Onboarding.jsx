import { h, Component } from 'preact';
import OnboardingWelcome from './components/OnboardingWelcome';
import OnboardingFollowTags from './components/OnboardingFollowTags';
import OnboardingFollowUsers from './components/OnboardingFollowUsers';
import OnboardingWelcomeThread from './components/OnboardingWelcomeThread';
import cancelSvg from '../../assets/images/cancel.svg';
import OnboardingProfile from './components/OnboardingProfile';

const getContentOfToken = token =>
  document.querySelector(`meta[name='${token}']`).content;
const getFormDataAndAppend = array => {
  const form = new FormData();
  array.forEach(item => form.append(item.key, item.value));
  return form;
};

class Onboarding extends Component {
  constructor() {
    super();
    this.handleNextButton = this.handleNextButton.bind(this);
    this.handleBackButton = this.handleBackButton.bind(this);
    this.closeOnboarding = this.closeOnboarding.bind(this);
    this.handleFollowTag = this.handleFollowTag.bind(this);
    this.handleNextHover = this.handleNextHover.bind(this);
    this.updateUserData = this.updateUserData.bind(this);
    this.getUserTags = this.getUserTags.bind(this);
    this.handleCheckAllUsers = this.handleCheckAllUsers.bind(this);
    this.handleCheckUser = this.handleCheckUser.bind(this);
    this.handleSaveAllArticles = this.handleSaveAllArticles.bind(this);
    this.handleSaveArticle = this.handleSaveArticle.bind(this);
    this.handleProfileChange = this.handleProfileChange.bind(this);
    this.getUsersToFollow = this.getUsersToFollow.bind(this);
    this.state = {
      pageNumber: 1,
      showOnboarding: false,
      userData: null,
      allTags: [],
      users: [],
      checkedUsers: [],
      followRequestSent: false,
      articles: [],
      savedArticles: [],
      profileInfo: {},
    };
  }

  componentDidMount() {
    this.updateUserData();
    this.getUserTags();
    document.getElementsByTagName('body')[0].classList.add('modal-open');
  }

  getUserTags() {
    fetch('/api/tags/onboarding')
      .then(response => response.json())
      .then(json => {
        const followedTagNames = JSON.parse(
          document.body.getAttribute('data-user'),
        ).followed_tag_names;
        function checkFollowingStatus(followedTags, jsonTags) {
          if (!followedTags || !followedTags.length) return jsonTags;
          const newJSON = jsonTags;
          jsonTags.map((tag, index) => {
            if (followedTags.includes(tag.name)) {
              newJSON[index].following = true;
            } else {
              newJSON[index].following = false;
            }
            return newJSON;
          });
          return newJSON;
        }
        const updatedJSON = checkFollowingStatus(followedTagNames, json);
        this.setState({ allTags: updatedJSON });
      })
      .catch(error => {
        console.log(error);
      });
  }

  getUsersToFollow() {
    const { users } = this.state;
    fetch('/api/users?state=follow_suggestions', {
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      credentials: 'same-origin',
    })
      .then(response => response.json())
      .then(json => {
        if (users.length === 0) {
          this.setState({ users: json, checkedUsers: json });
        }
      })
      .catch(error => {
        console.log(error);
      });
  }

  handleBulkFollowUsers(users) {
    const { checkedUsers, followRequestSent } = this.state;
    if (checkedUsers.length > 0 && !followRequestSent) {
      const csrfToken = getContentOfToken('csrf-token');
      const formData = getFormDataAndAppend([
        { key: 'users', value: JSON.stringify(users) },
      ]);

      fetch('/api/follows', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': csrfToken,
        },
        body: formData,
        credentials: 'same-origin',
      }).then(response => {
        if (response.ok) {
          this.setState({ followRequestSent: true });
        }
      });
    }
  }

  handleUserProfileSave() {
    const csrfToken = getContentOfToken('csrf-token');
    const { profileInfo } = this.state;
    const formData = getFormDataAndAppend([
      { key: 'user', value: JSON.stringify(profileInfo) },
    ]);
    fetch('/onboarding_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
      },
      body: formData,
      credentials: 'same-origin',
    });
  }

  updateUserData() {
    const userData = JSON.parse(document.body.getAttribute('data-user'));
    const { saw_onboarding: sawOnboarding } = userData;
    this.setState({
      userData,
      showOnboarding: !sawOnboarding,
    });
  }

  handleFollowTag(tag) {
    const csrfToken = getContentOfToken('csrf-token');
    const formData = getFormDataAndAppend([
      { key: 'followable_type', value: 'Tag' },
      { key: 'followable_id', value: tag.id },
      { key: 'verb', value: tag.following ? 'unfollow' : 'follow' },
    ]);

    this.setState(prevState => ({
      allTags: prevState.allTags.map(currentTag => {
        const newTag = currentTag;
        if (currentTag.name === tag.name) {
          newTag.following = true;
        }
        return newTag;
      }),
    }));

    fetch('/follows', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
      },
      body: formData,
      credentials: 'same-origin',
    })
      .then(response =>
        response.json().then(json => {
          this.setState(prevState => ({
            allTags: prevState.allTags.map(currentTag => {
              const newTag = currentTag;
              if (currentTag.name === tag.name) {
                newTag.following = json.outcome === 'followed';
              }
              return newTag;
              // add in optimistic rendering
            }),
          }));
        }),
      )
      .catch(error => {
        console.log(error);
      });
  }

  handleCheckAllUsers() {
    const { users, checkedUsers: prevCheckedUsers } = this.state;
    let checkedUsers = [];

    if (prevCheckedUsers.length < users.length) {
      checkedUsers = users.slice();
    }
    this.setState({ checkedUsers });
  }

  handleProfileChange(event) {
    const { name, value } = event.target;

    this.setState(prevState => ({
      profileInfo: {
        ...prevState.profileInfo,
        [name]: value,
      },
    }));
  }

  handleCheckUser(user) {
    const { checkedUsers } = this.state;
    const newCheckedUsers = checkedUsers.slice();
    const index = checkedUsers.indexOf(user);

    if (index > -1) {
      newCheckedUsers.splice(index, 1);
    } else {
      newCheckedUsers.push(user);
    }
    this.setState({ checkedUsers: newCheckedUsers });
  }

  handleSaveAllArticles() {
    const { savedArticles: prevSavedArticles, articles } = this.state;
    let savedArticles = [];
    if (prevSavedArticles.length < articles.length) {
      savedArticles = articles.slice();
    }
    this.setState({ savedArticles });
  }

  handleSaveArticle(article) {
    const { savedArticles } = this.state;
    const newSavedArticles = savedArticles.slice();
    const index = newSavedArticles.indexOf(article);
    if (index > -1) {
      newSavedArticles.splice(index, 1);
    } else {
      newSavedArticles.push(article);
    }
    this.setState({ savedArticles: newSavedArticles });
  }

  handleNextHover() {
    const { pageNumber, users } = this.state;
    if (pageNumber === 2 && users.length === 0) {
      this.getUsersToFollow();
    }
  }

  handleNextButton() {
    const { users, articles, checkedUsers, profileInfo } = this.state;
    let { pageNumber } = this.state;
    if (pageNumber === 2 && users.length === 0 && articles.length === 0) {
      this.getUsersToFollow();
    }
    if (pageNumber < 5) {
      pageNumber += 1;
      this.setState({ pageNumber });
      if (pageNumber === 4 && checkedUsers.length > 0) {
        this.handleBulkFollowUsers(checkedUsers);
      } else if (pageNumber === 5) {
        this.handleUserProfileSave(profileInfo);
      }
    } else if (pageNumber === 5) {
      this.closeOnboarding();
    }
  }

  handleBackButton() {
    const { pageNumber } = this.state;
    if (pageNumber > 1) {
      this.setState({ pageNumber: pageNumber - 1 });
    }
  }

  closeOnboarding() {
    const { pageNumber } = this.state;
    document.getElementsByTagName('body')[0].classList.remove('modal-open');
    const csrfToken = getContentOfToken('csrf-token');
    const formData = getFormDataAndAppend([
      { key: 'saw_onboarding', value: true },
    ]);

    if (window.ga && ga.create) {
      ga('send', 'event', 'click', 'close onboarding slide', pageNumber, null);
    }
    fetch('/onboarding_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
      },
      body: formData,
      credentials: 'same-origin',
    })
      .then(response => response.json())
      .then(json => {
        this.setState({ showOnboarding: json.outcome === 'onboarding opened' });
        // console.log('this is special')
        // console.log(this.state)
      })
      .catch(error => {
        console.log(error);
      });
  }

  toggleOnboardingSlide() {
    const ONBOARDING = {
      WELCOME_SCREEN: 1,
      FOLLOW_TAG_SCREEN: 2,
      FOLLOW_USERS_SCREEN: 3,
      PROFILE_SCREEN: 4,
      WELCOME_THREAD: 5,
    };

    const {
      pageNumber,
      userData,
      allTags,
      followedTags,
      users,
      checkedUsers,
    } = this.state;
    switch (pageNumber) {
      case ONBOARDING.WELCOME_SCREEN:
        return <OnboardingWelcome />;
      case ONBOARDING.FOLLOW_TAG_SCREEN:
        return (
          <OnboardingFollowTags
            userData={userData}
            allTags={allTags}
            followedTags={followedTags}
            handleFollowTag={this.handleFollowTag}
          />
        );
      case ONBOARDING.FOLLOW_USERS_SCREEN:
        return (
          <OnboardingFollowUsers
            users={users}
            checkedUsers={checkedUsers}
            handleCheckUser={this.handleCheckUser}
            handleCheckAllUsers={this.handleCheckAllUsers}
          />
        );
      case ONBOARDING.PROFILE_SCREEN:
        return <OnboardingProfile onChange={this.handleProfileChange} />;
      case ONBOARDING.WELCOME_THREAD:
        return <OnboardingWelcomeThread />;
      default:
        return null;
    }
  }

  renderCloseButton() {
    const btnClassName = 'close-button';
    return (
      <button
        className={btnClassName}
        type="button"
        onClick={this.closeOnboarding}
      >
        <img src={cancelSvg} alt="cancel button" />
      </button>
    );
  }

  renderBackButton() {
    const { pageNumber } = this.state;
    if (pageNumber > 1) {
      return (
        <button
          className="button cta"
          type="button"
          onClick={this.handleBackButton}
        >
          BACK
        </button>
      );
    }
    return null;
  }

  renderNextButton() {
    const { pageNumber } = this.state;
    return (
      <button
        className="button cta"
        onClick={this.handleNextButton}
        onMouseOver={this.handleNextHover}
        onFocus={this.handleNextHover}
        type="button"
      >
        {pageNumber < 5 ? 'NEXT' : "LET'S GO"}
      </button>
    );
  }

  renderPageIndicators() {
    const { pageNumber } = this.state;
    const firstIndicatorClassName =
      pageNumber === 2
        ? 'pageindicator pageindicator--active'
        : 'pageindicator';
    const secondIndicatorClassName =
      pageNumber === 3
        ? 'pageindicator pageindicator--active'
        : 'pageindicator';
    const thirdIndicatorClassName =
      pageNumber === 4
        ? 'pageindicator pageindicator--active'
        : 'pageindicator';
    return (
      <div className="pageindicators">
        <div className={firstIndicatorClassName} />
        <div className={secondIndicatorClassName} />
        <div className={thirdIndicatorClassName} />
      </div>
    );
  }

  renderSloanMessage() {
    const messages = {
      1: 'WELCOME!',
      2: 'FOLLOW TAGS',
      3: 'FOLLOW DEVS',
      4: 'CREATE YOUR PROFILE',
      5: 'GET INVOLVED',
    };
    const { pageNumber } = this.state;

    return messages[pageNumber];
  }

  render() {
    const { showOnboarding } = this.state;
    if (!showOnboarding) return null;

    return (
      <div className="global-modal" style={{ display: 'none' }}>
        <div className="global-modal-bg">{this.renderCloseButton()}</div>
        <div className="global-modal-inner">
          <div className="modal-header">
            <div className="triangle-isosceles">
              {this.renderSloanMessage()}
            </div>
          </div>
          <div className="modal-body">
            <div id="sloan-mascot-onboarding-area" className="sloan-bar wiggle">
              <img
                src="https://res.cloudinary.com/practicaldev/image/fetch/s--iiubRINO--/c_imagga_scale,f_auto,fl_progressive,q_auto,w_300/https://practicaldev-herokuapp-com.freetls.fastly.net/assets/sloan.png"
                className="sloan-img"
                alt="Sloan, the sloth mascot"
              />
            </div>
            <div className="body-message">{this.toggleOnboardingSlide()}</div>
          </div>
          <div className="modal-footer">
            <div className="modal-footer-left">{this.renderBackButton()}</div>
            <div className="modal-footer-center">
              {this.renderPageIndicators()}
            </div>
            <div className="modal-footer-right">{this.renderNextButton()}</div>
          </div>
        </div>
      </div>
    );
  }
}

export default Onboarding;
