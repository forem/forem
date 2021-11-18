import { h, Component, createRef } from 'preact';
// eslint-disable-next-line import/no-unresolved
import ConfigImage from 'images/overflow-horizontal.svg';

export class ConfigMenu extends Component {
  constructor() {
    super();
    this.state = { visible: false };
    this.firstNavLink = createRef();
    this.configMenuButton = createRef();
  }

  handleClick = () => {
    this.setState(
      (prevState) => ({ visible: !prevState.visible }),
      () => {
        this.state.visible
          ? this.firstNavLink.current.focus()
          : this.configMenuButton.current.focus();
      },
    );
  };

  render() {
    const { visible } = this.state;

    return (
      <div className="chatchannels__config">
        <button
          onClick={this.handleClick}
          aria-expanded={visible}
          aria-label="configuration navigation menu"
          style={{ backgroundImage: `url(${ConfigImage})` }}
          ref={this.configMenuButton}
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
