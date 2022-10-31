import { h } from 'preact';
import { Fieldset } from '../../../storybook-utilities/Fieldset';
import '../../../storybook-utilities/designSystem.scss';
import notes from '../../form-elements.mdx';

export default {
  title: 'Components/Form Elements/Checkbox',
  parameters: { notes },
};

export const Default = () => (
  <input type="checkbox" className="crayons-checkbox" />
);

Default.storyName = 'default';

export const Checked = () => (
  <input type="checkbox" className="crayons-checkbox" checked />
);

Checked.storyName = 'checked';

export const Disabled = () => (
  <input type="checkbox" className="crayons-checkbox" disabled />
);

Disabled.storyName = 'disabled';

export const CheckedAndDisabled = () => (
  <input type="checkbox" className="crayons-checkbox" checked disabled />
);

CheckedAndDisabled.storyName = 'checked (disabled)';

export const CheckboxWithLabel = () => (
  <div className="crayons-field crayons-field--checkbox">
    <input type="checkbox" id="c2" className="crayons-checkbox" />
    <label htmlFor="c2" className="crayons-field__label">
      Raspberry
    </label>
  </div>
);

CheckboxWithLabel.storyName = 'checkbox with <label />';

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

CheckboxWithLabelAndDisabled.storyName =
  'checkbox with <label /> and description';

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

CheckboxGroup.storyName = 'checkbox group';
