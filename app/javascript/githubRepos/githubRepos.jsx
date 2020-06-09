import { h, Component } from 'preact';
import { request } from '@utilities/http';
import { SingleRepo } from './singleRepo';

export class GithubRepos extends Component {
  state = {
    repos: [],
    erroredOut: false,
  };

  componentDidMount() {
    this.getGithubRepos();
  }

  async getGithubRepos() {
    try {
      const response = await request('/github_repos');
      const repositories = await response.json();

      this.setState({ repos: repositories });
    } catch (error) {
      this.setState({ erroredOut: true });

      Honeybadger.notify(error);

      // will remove this, need it temporarily to properly debug
      console.error(error); // eslint-disable-line no-console
    }
  }

  render() {
    const { repos, erroredOut } = this.state;
    if (erroredOut) {
      return (
        <div className="github-repos github-repos-errored">
          An error occurred. Please check your browser console and email
          <a href="mailto:yo@dev.to"> yo@dev.to </a>
          for more help.
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

    if (repos.length > 0) {
      return <div className="github-repos">{allRepos}</div>;
    }
    return <div className="github-repos loading-repos" />;
  }
}

GithubRepos.displayName = 'GitHub Repositories Wrapper';
