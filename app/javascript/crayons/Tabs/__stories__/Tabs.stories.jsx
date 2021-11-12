import { h } from 'preact';
import { Tabs, Tab } from '@crayons';
import Cog from '@img/cog.svg';
import Unicorn from '@img/unicorn.svg';
import Mod from '@img/mod.svg';

export default {
  component: Tabs,
  title: 'BETA/Navigation/Tabs',
  argTypes: {
    control: {
      control: {
        type: 'select',
        options: ['buttons', 'links'],
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
  control: 'buttons',
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
  control: 'buttons',
};
