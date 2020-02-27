import { h, Component } from 'preact';
import { SingleRepo } from './singleRepo';

export class GithubRepos extends Component {
  state = {
    repos: [],
    erroredOut: false,
  };

  componentDidMount() {
    this.getGithubRepos();
  }

  getGithubRepos = () => {
    fetch(`/github_repos`, {
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      credentials: 'same-origin',
    })
      .then(response => response.json())
      .then(json => {
        this.setState({ repos: json });
      })
      .catch(() => {
        this.setState({ erroredOut: true });
      });
  };

  render() {
    const { repos, erroredOut } = this.state;
    const allRepos = repos.map(repo => (
      <SingleRepo
        githubIdCode={repo.github_id_code}
        name={repo.name}
        fork={repo.fork}
        selected={repo.selected}
      />
    ));

    if (erroredOut) {
      return (
        <div className="github-repos github-repos-errored">
          An error occurred. Please check your browser console and email
          <a href="mailto:yo@dev.to"> yo@dev.to </a>
          for more help.
        </div>
      );
    }
    if (repos.length > 0) {
      return <div className="github-repos">{allRepos}</div>;
    }
    return <div className="github-repos loading-repos" />;
  }
}

GithubRepos.displayName = 'GitHub Repos Wrapper';
