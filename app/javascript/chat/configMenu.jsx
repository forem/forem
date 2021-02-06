import { h, Component, createRef } from 'preact';
import PropTypes from 'prop-types';
// eslint-disable-next-line import/no-unresolved
import ConfigImage from 'images/overflow-horizontal.svg';

export class ConfigMenu extends Component {
  static propTypes = {
    expanded: PropTypes.bool.isRequired,
  };

  constructor(props) {
    super(props);
    this.state = { visible: false };
    this.firstNavLink = createRef();
  }

  handleClick = () => {
    this.setState(
      (prevState) => ({ visible: !prevState.visible }),
      () => {
        this.state.visible && this.firstNavLink.current.focus();
      },
    );
  };

  render() {
    const { visible } = this.state;

    return (
      <div className="chatchannels__config">
        <button
          onClick={this.handleClick}
          aria-label="configuration menu"
          style={{ backgroundImage: `url(${ConfigImage})` }}
         />
        {visible && (
          <nav aria-label="configuration menu">
            <ul className="chatchannels__configmenu">
              <li>
                <a href="/settings" ref={this.firstNavLink}>
                  Settings
                </a>
              </li>
              <li>
                <a href="/report-abuse">Report Abuse</a>
              </li>
            </ul>
          </nav>
        )}
      </div>
    );
  }
}
