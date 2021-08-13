import { h, Fragment } from 'preact';
import { MobileDrawerNavigation } from '@crayons';

export default {
  title: 'App Components/MobileDrawerNavigation',
};

export const Default = () => {
  const { href, hash } = window.location;
  const indexOfHash = href.indexOf(hash) || href.length;
  const baseStoryUrl = href.substr(0, indexOfHash);

  const links = [
    {
      url: baseStoryUrl,
      displayName: 'Drawer Navigation',
      isCurrentPage: href === baseStoryUrl,
    },
    {
      url: `${baseStoryUrl}/#2`,
      displayName: 'Example link 2',
      isCurrentPage: `#2` === hash,
    },
    {
      url: `${baseStoryUrl}/#3`,
      displayName: 'Example link 3',
      isCurrentPage: `#3` === hash,
    },
    {
      url: `${baseStoryUrl}/#4`,
      displayName: 'Example link 4',
      isCurrentPage: `#4` === hash,
    },
  ];

  return (
    <Fragment>
      <MobileDrawerNavigation
        headingComponent="h2"
        navigationTitle="Example MobileDrawerNavigation"
        navigationLinks={links}
      />
      <p className="my-4">
        Click on the button to view and select navigation links.
      </p>
    </Fragment>
  );
};

Default.story = {
  name: 'MobileDrawerNavigation',
};
