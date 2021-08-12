import { h, Fragment } from 'preact';

import { MobileDrawerNavigation } from '@crayons';

export default {
  title: 'App Components/MobileDrawerNavigation',
};

export const Default = () => {
  return (
    <Fragment>
      <MobileDrawerNavigation
        headingComponent="h2"
        navigationTitle="Example MobileDrawerNavigation"
        navigationLinks={[
          {
            url: window.location.href,
            displayName: 'Drawer Navigation',
            isCurrentPage: true,
          },
          { url: '/#', displayName: 'Example link 2' },
          { url: '/#', displayName: 'Example link 3' },
          { url: '/#', displayName: 'Example link 4' },
        ]}
      />
      <p className="my-4">Click on the button to view navigation links.</p>
      <p>
        NB: As the component is only rendered on this page, "Drawer Navigation"
        will always be the current page.
      </p>
    </Fragment>
  );
};

Default.story = {
  name: 'MobileDrawerNavigation',
};
