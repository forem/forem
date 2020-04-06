import { h } from 'preact';
import { FormField, RadioButton } from '@crayons';

export default {
  title: 'Components/Form Components/Form Field',
};

export const RadioVariant = () => (
  <FormField variant="radio">
    <RadioButton id="some-id" name="some-radio-button" />
    <label htmlFor="some-id" className="crayons-field__label">
      Some Radio Button Text
    </label>
  </FormField>
);

RadioVariant.story = {
  name: 'radio',
};
