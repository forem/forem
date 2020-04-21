import { Component } from 'preact';
import PropTypes from 'prop-types';

let snackbarItems = [];

export function addSnackbarItem(snackbarItem) {
  snackbarItems.push(snackbarItem);
}

export class SnackbarPoller extends Component {
  state = {
    snacks: [],
  };

  pollingId;

  componentDidMount() {
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

        this.setState((prevState) => {
          const { snacks } = prevState;
          let updatedSnacks = [...snacks, ...newSnacks];

          if (updatedSnacks.length > 3) {
            updatedSnacks = updatedSnacks.slice(updatedSnacks.length - 3);
          }

          return { ...prevState, snacks: updatedSnacks };
        });
      }
    }, pollingTime);
  }

  decreaseLifespan(snack) {
    if (snack.lifespan === 0) {
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

    snack.lifespan -= 1; // eslint-disable-line no-param-reassign
    // eslint-disable-next-line no-param-reassign
    snack.lifespanTimeoutId = setTimeout(() => {
      this.decreaseLifespan(snack);
    }, 1000); // eslint-disable-line no-param-reassign
  }

  render() {
    const { snacks } = this.state;
    const [render] = this.props.children; // eslint-disable-line react/destructuring-assignment

    return render(snacks);
  }
}

SnackbarPoller.defaultProps = {
  lifespan: 5,
  pollingTime: 300,
};

SnackbarPoller.displayName = 'SnackbarPoller';

SnackbarPoller.propTypes = {
  children: PropTypes.func.isRequired,
  lifespan: PropTypes.number,
  pollingTime: PropTypes.number,
};
