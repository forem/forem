import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { ButtonNew as Button } from '@crayons';

export class SingleRepo extends Component {
  constructor(props) {
    super(props);
    const { featured } = this.props;
    this.state = { featured };
  }

  forkLabel = () => {
    const { fork } = this.props;
    if (fork) {
      return <span className="c-indicator c-indicator--warning">fork</span>;
    }
    return null;
  };

  submitRepo = () => {
    const { featured } = this.state;
    const { githubIdCode } = this.props;

    const submitButton = document.getElementById(
      `github-repo-button-${githubIdCode}`,
    );
    submitButton.textContent = '';
    submitButton.disabled = true;

    const csrfToken = document.querySelector("meta[name='csrf-token']").content;
    const formData = new FormData();
    const formAttributes = {
      github_id_code: githubIdCode,
      featured: !featured,
    };
    formData.append('github_repo', JSON.stringify(formAttributes));

    fetch('/github_repos/update_or_create', {
      method: 'POST',
      headers: {
        'X-CSRF-TOKEN': csrfToken,
      },
      body: formData,
      credentials: 'same-origin',
    })
      .then((response) => response.json())
      .then((json) => {
        submitButton.disabled = false;
        this.setState({ featured: json.featured });
      });
  };

  githubRepoClassName = () => {
    const { featured } = this.state;
    if (featured) {
      return 'github-repo-row github-repo-row-featured';
    }
    return 'github-repo-row';
  };

  render() {
    const { featured } = this.state;
    const { name, githubIdCode } = this.props;
    return (
      <div className={this.githubRepoClassName()}>
        <div className="github-repo-row-name">
          <div className="github-repo-row-label">
            {name}
            {this.forkLabel()}
          </div>
          <Button
            id={`github-repo-button-${githubIdCode}`}
            onClick={this.submitRepo}
          >
            {featured ? 'Remove' : 'Select'}
          </Button>
        </div>
      </div>
    );
  }
}

SingleRepo.displayName = 'Single GitHub Repo';

SingleRepo.propTypes = {
  name: PropTypes.string.isRequired,
  githubIdCode: PropTypes.number.isRequired,
  fork: PropTypes.bool.isRequired,
  featured: PropTypes.bool.isRequired,
};
