import { h, Component } from 'preact';
import PropTypes from 'prop-types';
import { Button, ButtonGroup } from '@crayons';
import { defaultChildrenPropTypes } from '../src/components/common-prop-types';

export class Snackbar extends Component {
  constructor(props) {
    super(props);

    const { children, lifespan = 5000 } = props;

    // 5 second lifespan by default before the snackbar is removed
    this.state = {
      lifespan,
      contents: children,
    };
  }

  componentDidMount() {
    const { lifespan } = this.state;

    setTimeout(() => {
      this.setState({ contents: undefined });
    }, lifespan);
  }

  render() {
    const { actions = [] } = this.props;
    const { contents } = this.state;

    return contents ? (
      <div className="crayons-snackbar">
        <div
          className="crayons-snackbar__item flex"
          ref={(element) => {
            this.element = element;
          }}
        >
          <div className="crayons-snackbar__body">{contents}</div>
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
      </div>
    ) : null;
  }
}

Snackbar.displayName = 'Snackbar';

Snackbar.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  actions: PropTypes.arrayOf(
    PropTypes.shape({
      text: PropTypes.string.isRequired,
      handler: PropTypes.func.isRequired,
    }),
  ).isRequired,
  lifespan: PropTypes.number.isRequired,
};
