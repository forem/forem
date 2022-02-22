import { h } from 'preact';
import ColorPickerDoc from './ColorPicker.mdx';
import { ColorPicker } from '@crayons';

export default {
  component: ColorPicker,
  title: 'Components/Form Elements/Color Picker',
  parameters: {
    docs: {
      page: ColorPickerDoc,
    },
  },
  argTypes: {
    id: {
      description:
        'A unique ID for the component. Required to make sure the popover operates correctly.',
    },
    buttonLabelText: {
      description:
        "Describes the button's function for users of assistive technologies. Should closely match the input label text.",
    },
    defaultValue: {
      description: 'The initial hex color value of the component',
      table: {
        defaultValue: { summary: '#000' },
      },
    },
    inputProps: {
      description:
        'Any additional props to be attached to the input element (e.g. onChange handler)',
    },
  },
};

export const Default = (args) => (
  <div className="crayons-field">
    {/* Disabled as the ColorPicker component attaches the correct ID to the input  */}
    {/* eslint-disable-next-line jsx-a11y/label-has-associated-control */}
    <label for={args.id} className="crayons-field__label">
      Choose a color
    </label>
    <ColorPicker {...args} />
  </div>
);

Default.args = {
  buttonLabelText: 'Choose a color',
  defaultValue: '#1ABC9C',
  id: 'color-picker',
};
