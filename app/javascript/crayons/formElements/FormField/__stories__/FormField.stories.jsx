import { h } from 'preact';
import { action } from '@storybook/addon-actions';
import notes from '../../form-elements.mdx';
import { FormField, RadioButton } from '@crayons';

export default {
  title: 'Components/Form Elements/Form Field',
  parameters: { notes },
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

RadioVariant.storyName = 'radio';
