import { h, Component } from 'preact';
import PropTypes from 'prop-types';

export class SingleRepo extends Component {
  constructor(props) {
    super(props);
    const { selected } = this.props;
    this.state = { selected };
  }

  forkLabel = () => {
    const { fork } = this.props;
    if (fork) {
      return <span className="github-repo-fork">fork</span>;
    }
    return null;
  };

  submitRepo = () => {
    const { selected } = this.state;
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
      featured: !selected,
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
      .then(response => response.json())
      .then(json => {
        submitButton.disabled = false;
        this.setState({ selected: json.featured });
      });
  };

  githubRepoClassName = () => {
    const { selected } = this.state;
    if (selected) {
      return 'github-repo-row github-repo-row-selected';
    }
    return 'github-repo-row';
  };

  render() {
    const { selected } = this.state;
    const { name, githubIdCode } = this.props;
    return (
      <div className={this.githubRepoClassName()}>
        <div className="github-repo-row-name">
          <button
            className="cta"
            type="button"
            id={`github-repo-button-${githubIdCode}`}
            onClick={this.submitRepo}
          >
            {selected ? 'REMOVE' : 'SELECT'}
          </button>
          {name}
          {this.forkLabel()}
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
  selected: PropTypes.bool.isRequired,
};
