import { h } from 'preact';
import { action } from '@storybook/addon-actions';
import { FormField, RadioButton } from '@crayons';

export default {
  title: '3_Components/Form Components/Form Field',
};

export const RadioVariant = () => (
  <FormField variant="radio">
    <RadioButton
      id="some-id"
      name="some-radio-button"
      onClick={action('clicked')}
    />
    <label htmlFor="some-id" className="crayons-field__label">
      Some Radio Button Text
    </label>
  </FormField>
);

RadioVariant.story = {
  name: 'radio',
};
