import { h, Component } from 'preact';
import { SingleRepo } from './singleRepo';
import { request } from '@utilities/http';

export class GithubRepos extends Component {
  state = {
    repos: [],
    error: false,
    errorMessage: '',
  };

  componentDidMount() {
    this.getGithubRepos();
  }

  async getGithubRepos() {
    try {
      const response = await request('/github_repos');
      if (response.ok) {
        const repositories = await response.json();
        this.setState({ repos: repositories });
      } else {
        throw new Error(response.statusText);
      }
    } catch (error) {
      Honeybadger.notify(error);
      this.setState({ error: true, errorMessage: error.toString() });
    }
  }

  render() {
    const { repos, error, errorMessage } = this.state;
    if (error) {
      return (
        <div className="github-repos github-repos-errored" role="alert">
          An error occurred: {errorMessage}
        </div>
      );
    }

    const allRepos = repos.map((repo) => (
      <SingleRepo
        key={repo.github_id_code}
        githubIdCode={repo.github_id_code}
        name={repo.name}
        fork={repo.fork}
        featured={repo.featured}
      />
    ));

    if (allRepos.length > 0) {
      return (
        <div className="github-repos" data-testid="github-repos-list">
          {allRepos}
        </div>
      );
    }
    return (
      <div
        title="Loading GitHub repositories"
        className="github-repos loading-repos"
      />
    );
  }
}

GithubRepos.displayName = 'GitHub Repositories Wrapper';
