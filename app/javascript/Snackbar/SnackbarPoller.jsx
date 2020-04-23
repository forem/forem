import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { Snackbar } from './Snackbar';
import { SnackbarItem } from './SnackbarItem';

let snackbarItems = [];

export function addSnackbarItem(snackbarItem) {
  snackbarItems.push(snackbarItem);
}

export class SnackbarPoller extends Component {
  state = {
    snacks: [],
  };

  pollingId;

  paused = false;

  pauseLifespan;

  resumeLifespan;

  componentDidMount() {
    this.initializePolling();
  }

  componentDidUpdate() {
    if (!this.pauseLifespan) {
      this.pauseLifespan = (_event) => {
        this.paused = true;
      };

      this.resumeLifespan = (event) => {
        event.stopPropagation();
        this.paused = false;
      };

      this.element.base.addEventListener('mouseover', this.pauseLifespan);
      this.element.base.addEventListener('mouseout', this.resumeLifespan, true);
    }
  }

  componentWillUnmount() {
    if (this.element) {
      this.element.base.removeEventListener('mouseover', this.pauseLifespan);
      this.element.base.addEventListener('mouseout', this.resumeLifespan);
    }
  }

  initializePolling() {
    const { pollingTime, lifespan } = this.props;

    this.pollingId = setInterval(() => {
      if (snackbarItems.length > 0) {
        // Need to add the lifespan to snackbar items because each second that goes by, we
        // decrease the lifespan until it is no more.
        const newSnacks = snackbarItems.map((snackbarItem) => ({
          ...snackbarItem,
          lifespan,
        }));

        newSnacks.forEach((snack) => {
          // eslint-disable-next-line no-param-reassign
          snack.lifespanTimeoutId = setTimeout(() => {
            this.decreaseLifespan(snack);
          }, 1000);
        });

        snackbarItems = [];

        this.updateSnackbarItems(newSnacks);
      }
    }, pollingTime);
  }

  updateSnackbarItems(newSnacks) {
    this.setState((prevState) => {
      let updatedSnacks = [...prevState.snacks, ...newSnacks];

      if (updatedSnacks.length > 3) {
        const snacksToBeDiscarded = updatedSnacks.slice(
          0,
          updatedSnacks.length - 3,
        );

        snacksToBeDiscarded.forEach(({ lifespanTimeoutId }) => {
          clearTimeout(lifespanTimeoutId);
        });

        updatedSnacks = updatedSnacks.slice(updatedSnacks.length - 3);
      }

      return { ...prevState, snacks: updatedSnacks };
    });
  }

  decreaseLifespan(snack) {
    /* eslint-disable  no-param-reassign */
    if (!this.paused && snack.lifespan === 0) {
      clearTimeout(snack.lifespanTimeoutId);

      this.setState((prevState) => {
        const snacks = prevState.snacks.filter(
          (currentSnack) => currentSnack !== snack,
        );

        return {
          ...prevState,
          snacks,
        };
      });

      return;
    }

    if (!this.paused) {
      snack.lifespan -= 1;
    }

    snack.lifespanTimeoutId = setTimeout(() => {
      this.decreaseLifespan(snack);
    }, 1000);
    /* eslint-enable  no-param-reassign */
  }

  render() {
    const { snacks } = this.state;

    return (
      <Snackbar
        ref={(element) => {
          this.element = element;
        }}
      >
        {snacks.map(({ message, actions = [] }) => (
          <SnackbarItem message={message} actions={actions} />
        ))}
      </Snackbar>
    );
  }
}

SnackbarPoller.defaultProps = {
  lifespan: 5,
  pollingTime: 300,
};

SnackbarPoller.displayName = 'SnackbarPoller';

SnackbarPoller.propTypes = {
  lifespan: PropTypes.number,
  pollingTime: PropTypes.number,
};
