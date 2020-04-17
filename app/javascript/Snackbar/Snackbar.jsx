import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { Button, ButtonGroup } from '@crayons';
import { defaultChildrenPropTypes } from '../src/components/common-prop-types';

const snackbarItems = [];

export const addSnackbarItem = (snackbarItem) => {
  snackbarItems.push(snackbarItem);
};

const SnackbarItem = ({ children, actions = [] }) => (
  <div className="crayons-snackbar__item flex">
    <div className="crayons-snackbar__body">{children}</div>
    <div className="crayons-snackbar__actions">
      <ButtonGroup>
        {actions.map(({ text, handler }) => (
          <Button variant="secondary" onClick={handler} key={text}>
            {text}
          </Button>
        ))}
      </ButtonGroup>
    </div>
  </div>
);

SnackbarItem.displayName = 'SnackbarItem';

SnackbarItem.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  actions: PropTypes.arrayOf(
    PropTypes.shape({
      text: PropTypes.string.isRequired,
      handler: PropTypes.func.isRequired,
    }),
  ).isRequired,
};

export class Snackbar extends Component {
  state = {
    snacks: [],
  };

  watching = true;

  watchId = 0;

  componentDidMount() {
    const { pollingTime } = this.props;

    const snackCheck = () => {
      if (snackbarItems.length > 0) {
        this.setState((prevState) => {
          const snacks = [...prevState.snacks, snackbarItems.pop()];

          return { snacks };
        });
      }
    };

    const pollForSnacks = () => {
      if (!this.watching) {
        clearTimeout(this.watchId);
        return;
      }

      snackCheck();

      this.watchId = setTimeout(pollForSnacks, pollingTime);
    };

    pollForSnacks();
  }

  componentWillUnmount() {
    this.watching = false;
  }

  render() {
    const { snacks } = this.state;

    return snacks.length > 0 ? (
      <div className="crayons-snackbar">
        {snacks.map(({ text, actions }) => (
          <SnackbarItem key={text} actions={actions}>
            {text}
          </SnackbarItem>
        ))}
      </div>
    ) : null;
  }
}

Snackbar.displayName = 'Snackbar';

Snackbar.defaultProps = {
  pollingTime: 300,
};

Snackbar.propTypes = {
  pollingTime: PropTypes.number,
};
