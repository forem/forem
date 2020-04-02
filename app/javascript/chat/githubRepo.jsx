import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import marked from 'marked';
import { getJSONContents } from './actions';

export default class GithubRepo extends Component {
  static propTypes = {
    githubToken: PropTypes.string.isRequired,
    resource: PropTypes.shape({
      args: PropTypes.string,
    }).isRequired,
  };

  constructor(props) {
    super(props);
    this.state = {
      root: true,
      directories: [],
      files: [],
      readme: null,
      content: null,
      token: props.githubToken,
      path: null,
    };
  }

  componentDidMount() {
    const { token } = this.state;
    const { resource } = this.props;
    if (token) {
      getJSONContents(
        `https://api.github.com/repos/${resource.args}/contents?access_token=${token}`,
        this.loadContent,
        this.loadFailure,
      );
      getJSONContents(
        `https://api.github.com/repos/${resource.args}/readme?access_token=${token}`,
        this.loadContent,
        this.loadFailure,
      );
    }
    this.setState({ path: resource.args });
  }

  handleItemClick = e => {
    const { token } = this.state;
    e.preventDefault();
    getJSONContents(
      `${e.target.dataset.apiUrl}&access_token=${token}`,
      this.loadContent,
      this.loadFailure,
    );
    this.setState({
      root: false,
      path: e.target.dataset.path,
    });
  };

  loadContent = response => {
    const files = [];
    const directories = [];
    if (response.message === 'Not Found') {
      this.setState({ path: 'Repo not found (misspelled or private?)' });
    } else if (Array.isArray(response)) {
      response.forEach(item => {
        if (item.type === 'file') {
          files.push(item);
        } else {
          directories.push(item);
        }
      });
      this.setState({
        files,
        directories,
      });
    } else if (response.path === 'README.md') {
      this.setState({
        readme: window.atob(response.content),
      });
    } else if (response.content) {
      this.setState({
        content: window.atob(response.content),
      });
    }
  };

  loadFailure = response => {
    this.setState({ path: response.message });
  };

  render() {
    const {
      token,
      content,
      path,
      directories: directoriesFromState,
      files: filesFromState,
      readme: readmeFromState,
      root,
    } = this.state;
    if (!token || token.length === 0) {
      return (
        <div className="activecontent__githubrepo">
          <div className="activecontent__githubrepoheader">
            <em>Authentication required</em>
          </div>
          <p>This feature is in internal alpha testing mode.</p>
        </div>
      );
    }
    if (content) {
      return (
        <div className="activecontent__githubrepo">
          <div className="activecontent__githubrepoheader">{path}</div>
          <pre>{content}</pre>
        </div>
      );
    }
    const directories = directoriesFromState.map(item => (
      <div className="activecontent__githubrepofilerow">
        <a
          href={item.html_url}
          data-api-url={item.url}
          data-path={item.path}
          onClick={this.handleItemClick}
        >
          <span role="img" aria-label="folder-emoji">
            📁
          </span>
          {' '}
          {item.name}
        </a>
      </div>
    ));
    const files = filesFromState.map(item => (
      <div className="activecontent__githubrepofilerow">
        <a
          href={item.html_url}
          data-api-url={item.url}
          data-path={item.path}
          onClick={this.handleItemClick}
        >
          {item.name}
        </a>
      </div>
    ));
    let readme = '';
    if (readmeFromState) {
      readme = (
        <div
          className="activecontent__githubreporeadme"
          // eslint-disable-next-line react/no-danger
          dangerouslySetInnerHTML={{
            __html: marked(readmeFromState),
          }}
        />
      );
    }
    if (root) {
      return (
        <div className="activecontent__githubrepo">
          <div className="activecontent__githubrepoheader">
            {/* eslint-disable-next-line jsx-a11y/anchor-has-content */}
            <a href="/Users/benhalpern/dev/dev.to_core/app" />
            {path}
          </div>
          <div className="activecontent__githubrepofiles activecontent__githubrepofiles--root">
            {directories}
            {files}
          </div>
          {readme}
        </div>
      );
    }
    return (
      <div className="activecontent__githubrepo">
        <div className="activecontent__githubrepoheader">{path}</div>
        <div className="activecontent__githubrepofiles">
          {directories}
          {files}
        </div>
      </div>
    );
  }
}
