import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import marked from 'marked';
import { getJSONContents } from './actions';

export default class GithubRepo extends Component {
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
    if (this.state.token) {
      getJSONContents(
        `https://api.github.com/repos/${this.props.resource.args}/contents?access_token=${this.state.token}`,
        this.loadContent,
        this.loadFailure,
      );
      getJSONContents(
        `https://api.github.com/repos/${this.props.resource.args}/readme?access_token=${this.state.token}`,
        this.loadContent,
        this.loadFailure,
      );
    }
    this.setState({ path: this.props.resource.args });
  }

  handleItemClick = e => {
    e.preventDefault();
    getJSONContents(
      `${e.target.dataset.apiUrl}&access_token=${this.state.token}`,
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
        response,
      });
    } else if (response.path === 'README.md') {
      this.setState({
        readme: window.atob(response.content),
      });
    } else if (response.content) {
      this.setState({
        content: window.atob(response.content),
        response,
      });
    }
  };

  loadFailure = response => {
    this.setState({ path: response.message });
  };

  render() {
    if (!this.state.token || this.state.token.length === 0) {
      return (
        <div className="activecontent__githubrepo">
          <div className="activecontent__githubrepoheader">
            <em>Authentication required</em>
          </div>
          <p>This feature is in internal alpha testing mode.</p>
        </div>
      );
    }
    if (this.state.content) {
      return (
        <div className="activecontent__githubrepo">
          <div className="activecontent__githubrepoheader">
            {this.state.path}
          </div>
          <pre>{this.state.content}</pre>
        </div>
      );
    }
    const directories = this.state.directories.map(item => (
      <div className="activecontent__githubrepofilerow">
        <a
          href={item.html_url}
          data-api-url={item.url}
          data-path={item.path}
          onClick={this.handleItemClick}
        >
          📁 {item.name}
        </a>
      </div>
    ));
    const files = this.state.files.map(item => (
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
    if (this.state.readme) {
      readme = (
        <div
          className="activecontent__githubreporeadme"
          dangerouslySetInnerHTML={{
            __html: marked(this.state.readme),
          }}
        />
      );
    }
    if (this.state.root) {
      return (
        <div className="activecontent__githubrepo">
          <div className="activecontent__githubrepoheader">
            <a href="/Users/benhalpern/dev/dev.to_core/app" />
            {this.state.path}
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
        <div className="activecontent__githubrepoheader">{this.state.path}</div>
        <div className="activecontent__githubrepofiles">
          {directories}
          {files}
        </div>
      </div>
    );
  }
}
