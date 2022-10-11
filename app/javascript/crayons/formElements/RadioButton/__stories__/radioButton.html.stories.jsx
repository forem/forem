import { h } from 'preact';
import { Fieldset } from '../../../storybook-utilities/Fieldset';
import '../../../storybook-utilities/designSystem.scss';

export default { title: 'Components/Form Elements/Radio Button/HTML' };

export const Default = () => (
  <input type="radio" name="n1" className="crayons-radio" />
);

Default.storyName = 'default';

export const Checked = () => (
  <input type="radio" name="n1" className="crayons-radio" checked />
);

Checked.storyName = 'checked';

export const Disabled = () => (
  <input type="radio" name="n2" className="crayons-radio" disabled />
);

Disabled.storyName = 'disabled';

export const CheckedAndDisabled = () => (
  <input type="radio" name="n2" className="crayons-radio" checked disabled />
);

CheckedAndDisabled.storyName = 'checked (disabled)';

export const WithLabel = () => (
  <div className="crayons-field crayons-field--radio">
    <input type="radio" name="name1" id="r2" className="crayons-radio" />
    <label htmlFor="r2" className="crayons-field__label">
      Raspberry
    </label>
  </div>
);

WithLabel.storyName = 'with <label />';

export const WithLabelAndDescription = () => (
  <div className="crayons-field crayons-field--radio">
    <input type="radio" name="name1" id="r2" className="crayons-radio" />
    <label htmlFor="r2" className="crayons-field__label">
      Raspberry
      <p className="crayons-field__description">
        This is some description for a textfield lorem ipsum...
      </p>
    </label>
  </div>
);

WithLabelAndDescription.storyName = 'with <label /> and description';

export const RadioButtonGroup = () => (
  <Fieldset>
    <div className="crayons-field crayons-field--radio">
      <input type="radio" name="radioGroup" id="r1" className="crayons-radio" />
      <label htmlFor="r1" className="crayons-field__label">
        Raspberry
      </label>
    </div>
    <div className="crayons-field crayons-field--radio">
      <input type="radio" name="radioGroup" id="r2" className="crayons-radio" />
      <label htmlFor="r2" className="crayons-field__label">
        Strawberry
      </label>
    </div>
    <div className="crayons-field crayons-field--radio">
      <input type="radio" name="radioGroup" id="r3" className="crayons-radio" />
      <label htmlFor="r3" className="crayons-field__label">
        Blueberry
      </label>
    </div>
  </Fieldset>
);

RadioButtonGroup.storyName = 'radio button group';
