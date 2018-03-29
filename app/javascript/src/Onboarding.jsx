import { h, render, Component } from 'preact';
import OnboardingWelcome from './components/OnboardingWelcome';
import OnboardingFollowTags from './components/OnboardingFollowTags';
import OnboardingFollowUsers from './components/OnboardingFollowUsers';
import OnboardingWelcomeThread from './components/OnboardingWelcomeThread';
import cancelSvg from '../../assets/images/cancel.svg';

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
    this.getUsersToFollow = this.getUsersToFollow.bind(this);
    this.state = {
      pageNumber: 1,
      showOnboarding: false,
      userData: null,
      allTags: [],
      users: [],
      checkedUsers: [],
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
      .then((json) => {
        const followedTagNames = JSON.parse(document.body.getAttribute('data-user')).followed_tag_names;
        function checkFollowingStatus(followedTags, jsonTags) {
          const newJSON = jsonTags;
          jsonTags.map((tag, index) => {
            if (followedTags.includes(tag.name)) {
              newJSON[index].following = true;
            } else { newJSON[index].following = false; }
            return newJSON;
          });
          return newJSON;
        }
        const updatedJSON = checkFollowingStatus(followedTagNames, json);
        this.setState({ allTags: updatedJSON });
      })
      .catch((error) => {
        console.log(error);
      });
  }

  getUsersToFollow() {
    fetch('/api/users?state=follow_suggestions', {
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      credentials: 'same-origin',
    })
      .then(response => response.json())
      .then((json) => {
        if (this.state.users.length === 0) {
          this.setState({ users: json, checkedUsers: json });
        }
      })
      .catch((error) => {
        console.log(error);
      });
  }

  handleBulkFollowUsers(users) {
    if (this.state.checkedUsers.length > 0) {
      const csrfToken = document.querySelector("meta[name='csrf-token']").content;

      const formData = new FormData();
      formData.append('users', JSON.stringify(users));

      fetch('/api/follows', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': csrfToken,
        },
        body: formData,
        credentials: 'same-origin',
      }).then(() => {
      });
    }
  }

  updateUserData() {
    this.setState({ userData: JSON.parse(document.body.getAttribute('data-user')) });
    if (this.state.userData.saw_onboarding === true) {
      this.setState({ showOnboarding: false });
    } else {
      this.setState({ showOnboarding: true });
    }
  }

  handleFollowTag(tag) {
    const csrfToken = document.querySelector("meta[name='csrf-token']").content;

    const formData = new FormData();
    formData.append('followable_type', 'Tag');
    formData.append('followable_id', tag.id);
    formData.append('verb', (tag.following ? 'unfollow' : 'follow'));
    formData.append('authenticity_token', csrfToken);

    fetch('/follows', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
      },
      body: formData,
      credentials: 'same-origin',
    })
      .then((response) => {
        // change allTags state
        // this.setState({ allTags: [] });
        return response.json().then((json) => {
          this.setState({
            allTags: this.state.allTags.map((currentTag) => {
              const newTag = currentTag;
              if (currentTag.name === tag.name) {
                newTag.following = json.outcome === 'followed';
              }
              return newTag;
              // add in optimistic rendering
            }),
          });
        });
      })
      .catch((error) => {
        console.log(error);
      });
  }


  handleCheckAllUsers() {
    if (this.state.checkedUsers.length < 50) {
      this.setState({ checkedUsers: this.state.users.slice() });
    } else {
      this.setState({ checkedUsers: [] });
    }
  }

  handleCheckUser(user) {
    const newCheckedUsers = this.state.checkedUsers.slice();
    if (this.state.checkedUsers.indexOf(user) > -1) {
      const index = newCheckedUsers.indexOf(user);
      newCheckedUsers.splice(index, 1);
    } else {
      newCheckedUsers.push(user);
    }
    this.setState({ checkedUsers: newCheckedUsers });
  }

  handleNextButton() {
    if (this.state.pageNumber === 2 && this.state.users.length === 0) {
      this.getUsersToFollow();
    }
    if (this.state.pageNumber < 4) {
      this.setState({ pageNumber: this.state.pageNumber + 1 });
    } else if (this.state.pageNumber === 4) {
      this.closeOnboarding();
    }
  }

  handleBackButton() {
    if (this.state.pageNumber > 1) {
      this.setState({ pageNumber: this.state.pageNumber - 1 });
    }
  }

  closeOnboarding() {
    document.getElementsByTagName('body')[0].classList.remove('modal-open');
    this.handleBulkFollowUsers(this.state.checkedUsers);
    const csrfToken = document.querySelector("meta[name='csrf-token']").content;
    const formData = new FormData();
    formData.append('saw_onboarding', true);

    fetch('/onboarding_update', {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': csrfToken,
      },
      body: formData,
      credentials: 'same-origin',
    })
      .then(response => response.json())
      .then((json) => {
        this.setState({ showOnboarding: json.outcome === 'onboarding opened' });
        // console.log('this is special')
        // console.log(this.state)
      })
      .catch((error) => {
        console.log(error);
      });
  }

  toggleOnboardingSlide() {
    if (this.state.pageNumber === 1) {
      return <OnboardingWelcome />;
    } else if (this.state.pageNumber === 2) {
      return (
        <OnboardingFollowTags
          userData={this.state.userData}
          allTags={this.state.allTags}
          followedTags={this.state.followedTags}
          handleFollowTag={this.handleFollowTag}
        />
      );
    } else if (this.state.pageNumber === 3) {
      return (
        <OnboardingFollowUsers
          users={this.state.users}
          checkedUsers={this.state.checkedUsers}
          handleCheckUser={this.handleCheckUser}
          handleCheckAllUsers={this.handleCheckAllUsers}
        />
      );
    } else if (this.state.pageNumber === 4) {
      return (
        <OnboardingWelcomeThread />
      );
    }
  }

  renderBackButton() {
    if (this.state.pageNumber > 1) {
      return (
        <button className="button cta" onClick={this.handleBackButton}> BACK </button>
      );
    }
  }

  handleNextHover() {
    if (this.state.pageNumber === 2 && this.state.users.length === 0) {
      this.getUsersToFollow();
    }
  }

  renderNextButton() {
    const onclick = this.handleNextButton;
    return (
      <button className="button cta" onClick={this.handleNextButton} onMouseOver={this.handleNextHover}>
        {this.state.pageNumber < 4 ? 'NEXT' : "LET'S GO"}
      </button>
    );
  }

  renderSloanMessage() {
    const messages = {
      1: 'WELCOME!',
      2: 'FOLLOW TAGS!',
      3: 'FOLLOW SOME DEVS!',
      4: 'GET INVOLVED!',
    };
    return messages[this.state.pageNumber];
  }

  render() {
    if (this.state.showOnboarding) {
      return (
        <div className="global-modal">
          <div className="global-modal-bg">
            <button className="close-button" onClick={this.closeOnboarding}>
              <img src={cancelSvg} alt="cancel button" />
            </button>
          </div>
          <div className="global-modal-inner">
            <div className="modal-header">
              <div className="triangle-isosceles">
                {this.renderSloanMessage()}
              </div>
            </div>
            <div className="modal-body">
              <div className="sloan-bar">
                <img src="https://res.cloudinary.com/practicaldev/image/fetch/s--iiubRINO--/c_imagga_scale,f_auto,fl_progressive,q_auto,w_300/https://practicaldev-herokuapp-com.freetls.fastly.net/assets/sloan.png" className="sloan-img"/>
              </div>
              <div className="body-message">
                {this.toggleOnboardingSlide()}
              </div>
            </div>
            <div className="modal-footer">
              <div className="modal-footer-left">
                {this.renderBackButton()}
              </div>
              <div className="modal-footer-center" />
              <div className="modal-footer-right">
                {this.renderNextButton()}
              </div>
            </div>
          </div>
        </div>
      );
    }
  }
}

export default Onboarding;
