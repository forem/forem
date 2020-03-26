import { addons } from '@storybook/addons';
import { create } from '@storybook/theming/create';

const crayonsTheme = create({
  base: 'light',
  brandTitle: '🖍️ Crayons 🖍️',
});

addons.setConfig({
  theme: crayonsTheme,
});
