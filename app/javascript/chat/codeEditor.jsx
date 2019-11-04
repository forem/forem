import { h, Component } from 'preact';
import PropTypes from 'prop-types';

export default class CodeEditor extends Component {
  static propTypes = {
    activeChannelId: PropTypes.string.isRequired,
  };

  componentDidMount() {
    const { activeChannelId } = this.props;
    import('codemirror').then(CodeMirror => {
      const editor = document.getElementById('codeeditor');
      const myCodeMirror = CodeMirror(editor, {
        mode: 'javascript',
        theme: 'material',
        autofocus: true,
      });
      myCodeMirror.setSize('100%', '100%');
      // Initial trigger:
      const channel = window.pusher.channel(
        `presence-channel-${activeChannelId}`,
      );
      channel.trigger('client-livecode', {
        context: 'initializing-live-code-channel',
        channel: `presence-channel-${activeChannelId}`,
      });
      // Coding trigger:
      myCodeMirror.on('keyup', cm => {
        channel.trigger('client-livecode', {
          keyPressed: true,
          value: cm.getValue(),
          cursorPos: cm.getCursor(),
        });
      });
    });
  }

  shouldComponentUpdate() {
    return false;
  }

  render() {
    return (
      <div id="codeeditor" className="chatcodeeditor">
        <div className="chatcodeeditor__header">Experimental (WIP)</div>
      </div>
    );
  }
}
