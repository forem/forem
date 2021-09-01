import { h } from 'preact';
import { Fieldset } from '../../../storybook-utilities/Fieldset';
import '../../../storybook-utilities/designSystem.scss';
import notes from '../../form-elements.md';

export default {
  title: 'Components/Form Components/Checkbox/HTML',
  parameters: { notes },
};

export const Default = () => (
  <input type="checkbox" className="crayons-checkbox" />
);

Default.story = {
  name: 'default',
};

export const Checked = () => (
  <input type="checkbox" className="crayons-checkbox" checked />
);

Checked.story = { name: 'checked' };

export const Disabled = () => (
  <input type="checkbox" className="crayons-checkbox" disabled />
);

Disabled.story = { name: 'disabled' };

export const CheckedAndDisabled = () => (
  <input type="checkbox" className="crayons-checkbox" checked disabled />
);

CheckedAndDisabled.story = {
  name: 'checked (disabled)',
};

export const CheckboxWithLabel = () => (
  <div className="crayons-field crayons-field--checkbox">
    <input type="checkbox" id="c2" className="crayons-checkbox" />
    <label htmlFor="c2" className="crayons-field__label">
      Raspberry
    </label>
  </div>
);

CheckboxWithLabel.story = { name: 'checkbox with <label />' };

export const CheckboxWithLabelAndDisabled = () => (
  <div className="crayons-field crayons-field--checkbox">
    <input type="checkbox" id="c2" className="crayons-checkbox" />
    <label htmlFor="c2" className="crayons-field__label">
      Raspberry
      <p className="crayons-field__description">
        This is some description for a textfield lorem ipsum...
      </p>
    </label>
  </div>
);

CheckboxWithLabelAndDisabled.story = {
  name: 'checkbox with <label /> and description',
};

export const CheckboxGroup = () => (
  <Fieldset>
    <div className="crayons-field crayons-field--checkbox">
      <input
        type="checkbox"
        name="checkboxGroup"
        id="c1"
        className="crayons-checkbox"
      />
      <label htmlFor="c1" className="crayons-field__label">
        Raspberry
      </label>
    </div>
    <div className="crayons-field crayons-field--checkbox">
      <input
        type="checkbox"
        name="checkboxGroup"
        id="c2"
        className="crayons-checkbox"
      />
      <label htmlFor="c2" className="crayons-field__label">
        Strawberry
      </label>
    </div>
    <div className="crayons-field crayons-field--checkbox">
      <input
        type="checkbox"
        name="checkboxGroup"
        id="c3"
        className="crayons-checkbox"
      />
      <label htmlFor="c3" className="crayons-field__label">
        Blueberry
      </label>
    </div>
  </Fieldset>
);

CheckboxGroup.story = {
  name: 'checkbox group',
};
