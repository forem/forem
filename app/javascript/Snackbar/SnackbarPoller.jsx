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
