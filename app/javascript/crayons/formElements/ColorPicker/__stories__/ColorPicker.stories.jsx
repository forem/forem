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
    labelText: {
      description:
        'Label text for the field. This text is required, but the label can be hidden with the showLabel prop',
    },
    showLabel: {
      description:
        'Whether to show the visible label, or keep it only for assistive technologies to consume',
      table: {
        defaultValue: { summary: true },
      },
    },
    defaultValue: {
      description: 'The initial hex color value of the component',
      table: {
        defaultValue: { summary: '#000' },
      },
    },
  },
};

export const Default = (args) => <ColorPicker id="color-picker" {...args} />;

Default.args = {
  labelText: 'Choose a color',
  defaultValue: '#1ABC9C',
  showLabel: true,
};
