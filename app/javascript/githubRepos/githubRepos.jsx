import { h, Component } from 'preact';
import { request } from '@utilities/http';
import { SingleRepo } from './singleRepo';

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
      this.setState({ error: true, errorMessage: error.toString() });

      Honeybadger.notify(error);

      // will remove this, need it temporarily to properly debug
      console.error(error); // eslint-disable-line no-console
    }
  }

  render() {
    const { repos, error, errorMessage } = this.state;
    if (error) {
      return (
        <div className="github-repos github-repos-errored">
          An error occurred: 
          {' '}
          {errorMessage}
        </div>
      );
    }

    const allRepos = repos.map((repo) => (
      <SingleRepo
        githubIdCode={repo.github_id_code}
        name={repo.name}
        fork={repo.fork}
        featured={repo.featured}
      />
    ));

    if (allRepos.length > 0) {
      return <div className="github-repos">{allRepos}</div>;
    }
    return <div className="github-repos loading-repos" />;
  }
}

GithubRepos.displayName = 'GitHub Repositories Wrapper';
