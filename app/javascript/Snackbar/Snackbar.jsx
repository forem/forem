import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { SnackbarItem } from './SnackbarItem';

let snackbarItems = [];

export function addSnackbarItem(snackbarItem) {
  if (!Array.isArray(snackbarItem.actions)) {
    snackbarItem.actions = []; // eslint-disable-line no-param-reassign
  }

  snackbarItems.push(snackbarItem);
}

export class Snackbar extends Component {
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

      this.element.addEventListener('mouseover', this.pauseLifespan);
      this.element.addEventListener('mouseout', this.resumeLifespan, true);
    }
  }

  componentWillUnmount() {
    if (this.element) {
      this.element.removeEventListener('mouseover', this.pauseLifespan);
      this.element.addEventListener('mouseout', this.resumeLifespan);
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

        snackbarItems = [];

        this.updateSnackbarItems(newSnacks);

        // Start the lifespan countdowns for each new snackbar item.
        newSnacks.forEach((snack) => {
          // eslint-disable-next-line no-param-reassign
          snack.lifespanTimeoutId = setTimeout(() => {
            this.decreaseLifespan(snack);
          }, 1000);

          if (snack.addCloseButton) {
            // Adds an optional close button if addDefaultACtion is true.
            snack.actions.push({
              text: 'Dismiss',
              handler: () => {
                this.setState((prevState) => {
                  return {
                    prevState,
                    snacks: prevState.snacks.filter(
                      (potentialSnackToFilterOut) =>
                        potentialSnackToFilterOut !== snack,
                    ),
                  };
                });
              },
            });
          }
        });
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
      <div
        className={snacks.length > 0 ? 'crayons-snackbar' : 'hidden'}
        ref={(element) => {
          this.element = element;
        }}
      >
        {snacks.map(({ message, actions = [] }, index) => (
          <SnackbarItem message={message} actions={actions} key={index} />
        ))}
      </div>
    );
  }
}

Snackbar.defaultProps = {
  lifespan: 5,
  pollingTime: 300,
};

Snackbar.displayName = 'Snackbar';

Snackbar.propTypes = {
  lifespan: PropTypes.number,
  pollingTime: PropTypes.number,
};
