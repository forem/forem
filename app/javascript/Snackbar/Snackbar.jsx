import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { Button, ButtonGroup } from '@crayons';
import { defaultChildrenPropTypes } from '../src/components/common-prop-types';

const snackbarItems = [];

export const addSnackbarItem = (snackbarItem) => {
  snackbarItems.push(snackbarItem);
};

// This component is never used on it's own, so no need to export it.
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

  snackbarElement;

  watching = true;

  watchId = 0;

  paused = false;

  eventsRegistered = false;

  constructor(props) {
    super(props);

    this.pollSnack.bind(this);
    this.mouseOver.bind(this);
    // this.mouseOut.bind(this);
  }

  componentDidMount() {
    this.snackbarElement.addEventListener('mouseover', this.mouseOver);

    // TODO: if more than 3 snacks, delete the oldest, so we always have 3 only at most
    const { pollingTime, lifespan } = this.props;

    const snackCheck = () => {
      if (snackbarItems.length > 0) {
        const snack = {
          ...snackbarItems.pop(),
          timesLeftToPoll: lifespan,
        };
        const snackPollingId = setInterval(() => {
          this.pollSnack(snack, snackPollingId);
        }, 1000);

        this.setState((prevState) => {
          const snacks = [snack, ...prevState.snacks];

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

  // componentDidUpdate() {
  //   if (!this.eventsRegistered) {
  //     // We're adding event listeners here instead of in componentDidMount
  //     // because the ref to the snackbar element only happens on the second render.
  //     this.snackbarElement.addEventListener('mouseover', this.mouseOver);
  //     this.snackbarElement.addEventListener('mouseout', this.mouseOut);
  //     this.eventsRegistered = true;
  //   }
  // }

  componentWillUnmount() {
    // this.snackbarElement.removeEventListener('mouseover', this.mouseOver);
    // this.snackbarElement.removeEventListener('mouseout', this.mouseOut);
    window.this.watching = false;
  }

  mouseOver(_event) {
    this.paused = true;
  }

  // mouseOut(event) {
  //   const { currentTarget } = event;

  //   this.paused = !currentTarget.classList.contains('crayons-snackbar');
  // }

  pollSnack(snack, snackPollingId) {
    if (this.paused) {
      return;
    }

    snack.timesLeftToPoll -= 1; // eslint-disable-line no-param-reassign

    this.setState((prevState) => {
      const { snacks } = prevState;
      const snackPosition = snacks.indexOf(snack);

      const updatedSnacks = [snack, ...snacks.filter((s) => s !== snack)];

      return { ...prevState, snacks: updatedSnacks };
    });

    if (snack.timesLeftToPoll === 0) {
      clearInterval(snackPollingId);

      this.setState((prevState) => {
        const snacks = prevState.snacks.filter(
          (currentSnack) => currentSnack !== snack,
        );

        return { snacks };
      });
    }
  }

  render() {
    const { snacks = [] } = this.state;

    return (
      <div
        className={snacks.length > 0 ? 'crayons-snackbar' : 'hidden'}
        ref={(element) => {
          this.snackbarElement = element;
        }}
      >
        {snacks.map(({ text, actions }) => (
          <SnackbarItem key={text} actions={actions}>
            {text}
          </SnackbarItem>
        ))}
      </div>
    );
  }
}

Snackbar.displayName = 'Snackbar';

Snackbar.defaultProps = {
  pollingTime: 300,
  lifespan: 5,
};

Snackbar.propTypes = {
  pollingTime: PropTypes.number,
  lifespan: PropTypes.number,
};
