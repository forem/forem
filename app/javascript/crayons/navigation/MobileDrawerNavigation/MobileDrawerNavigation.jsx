import { h, Fragment } from 'preact';
import { useState } from 'preact/hooks';
import { MobileDrawer } from '@crayons/MobileDrawer';
import { Button } from '@crayons/Button';

// TODO:
//  displays a heading, and a ... button
// displays the drawer when open
export const MobileDrawerNavigation = ({
  headingComponent,
  navigationTitle,
  navigationLinks,
}) => {
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const currentPageIndex = navigationLinks.findIndex(
    (item) => item.isCurrentPage,
  );

  const Heading = headingComponent;

  //   TODO: add aria-current to the current page
  return (
    <Fragment>
      <div className="flex justify-between">
        <Heading>Current url name</Heading>
        <Button onClick={() => setIsDrawerOpen(true)}>Open me</Button>
      </div>

      {isDrawerOpen && (
        <MobileDrawer
          title={navigationTitle}
          onClose={() => setIsDrawerOpen(false)}
        >
          <nav aria-label={navigationTitle}>
            <ul className="list-none">
              {navigationLinks.map((linkDetails, index) => (
                <li key={`link-${linkDetails.url}`} className="py-2">
                  <a href={linkDetails.url}>{linkDetails.displayName}</a>
                  {currentPageIndex === index && '!!'}
                </li>
              ))}
            </ul>
          </nav>
          <Button
            variant="secondary"
            className="w-100 mt-4"
            onClick={() => setIsDrawerOpen(false)}
          >
            Cancel
          </Button>
        </MobileDrawer>
      )}
    </Fragment>
  );
};
