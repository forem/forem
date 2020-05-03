import { h } from 'preact';
import { textFieldPropTypes } from '../../src/components/common-prop-types';

const TextField = ({ label, id, value, onKeyUp }) => {
  return (
    <div>
      <label htmlFor={id}>{label}</label>
      <input type="text" value={value} name={id} onKeyUp={onKeyUp} id={id} />
    </div>
  );
};

TextField.propTypes = textFieldPropTypes;

export default TextField;
