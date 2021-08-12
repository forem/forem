import { h } from 'preact';

import { MobileDrawerNavigation } from '@crayons';

export default {
  title: 'App Components/MobileDrawerNavigation',
};

export const Default = () => (
  <MobileDrawerNavigation
    headingComponent="h2"
    navigationTitle="Example MobileDrawerNavigation"
    navigationLinks={[
      { url: '/#', displayName: 'Example link 1', isCurrentPage: true },
      { url: '/#', displayName: 'Example link 2' },
      { url: '/#', displayName: 'Example link 3' },
      { url: '/#', displayName: 'Example link 4' },
    ]}
  />
);

Default.story = {
  name: 'MobileDrawerNavigation',
};
