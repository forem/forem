import { h } from 'preact';
import TabsDoc from './Tabs.mdx';
import { Tabs, Tab } from '@crayons';
import Cog from '@img/cog.svg';
import Unicorn from '@img/unicorn.svg';
import Mod from '@img/mod.svg';

export default {
  component: Tabs,
  parameters: {
    docs: {
      page: TabsDoc,
    },
  },
  title: 'BETA/Navigation/Tabs',
  argTypes: {
    elements: {
      description:
        'Depending on scenario you can either use `<button>` or `<a>` elements for individual tabs. These will be generated automatically but you need to provide appropriate attributes (e.g. `onClick` for buttons or `href` for links)',
      table: {
        defaultValue: { summary: 'buttons' },
      },
      control: {
        type: 'select',
        options: ['buttons', 'links'],
      },
      type: {
        required: true,
      },
    },
    stacked: {
      description:
        'Tabs can be either horizontal (default behavior) or vertical (`stacked`).',
      table: {
        defaultValue: { summary: false },
      },
    },
    fitted: {
      description:
        'Tabs can be sized automatically (i.e. individual tab will be as wide as its content) OR they can take full available space (for 2 tabs: each will be 1/2 of the container, for 3 tabs: each will be 1/3 of the container, and so on)',
      table: {
        defaultValue: { summary: false },
      },
    },
  },
};

export const Default = (args) => (
  <Tabs {...args}>
    <Tab current>First</Tab>
    <Tab>Second</Tab>
    <Tab>Third</Tab>
  </Tabs>
);

Default.args = {
  elements: 'buttons',
  stacked: false,
  fitted: false,
};

export const Fitted = (args) => (
  <Tabs {...args}>
    <Tab current>First</Tab>
    <Tab>Second</Tab>
    <Tab>Third</Tab>
  </Tabs>
);

Fitted.args = {
  ...Default.args,
  fitted: true,
};

export const Stacked = (args) => (
  <Tabs {...args}>
    <Tab current>First</Tab>
    <Tab>Second</Tab>
    <Tab>Third</Tab>
  </Tabs>
);

Stacked.args = {
  ...Default.args,
  stacked: true,
};

export const WithIcon = (args) => (
  <Tabs {...args}>
    <Tab icon={Cog} current>
      First
    </Tab>
    <Tab icon={Unicorn}>Second</Tab>
    <Tab icon={Mod}>Third</Tab>
  </Tabs>
);

WithIcon.args = {
  ...Default.args,
  elements: 'buttons',
};
