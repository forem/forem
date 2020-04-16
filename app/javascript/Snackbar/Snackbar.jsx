import { h } from 'preact';
import PropTypes from 'prop-types';
import { Button, ButtonGroup } from '@crayons';
import { defaultChildrenPropTypes } from '../src/components/common-prop-types';

export const Snackbar = ({ children, actions = [] }) => (
  <div className="crayons-snackbar__item flex">
    <div className="crayons-snackbar__body">{children}</div>
    <div className="crayons-snackbar__actions">
      {/* TODO: Figure out what the key should be for mapped buttons */}
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

Snackbar.displayName = 'Snackbar';

Snackbar.propTypes = {
  children: defaultChildrenPropTypes.isRequired,
  actions: PropTypes.arrayOf(
    PropTypes.shape({
      text: PropTypes.string.isRequired,
      handler: PropTypes.func.isRequired,
    }),
  ).isRequired,
};
