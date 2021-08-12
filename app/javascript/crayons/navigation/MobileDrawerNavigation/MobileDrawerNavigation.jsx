import { h, Fragment } from 'preact';
import { useState } from 'preact/hooks';
import { MobileDrawer } from '@crayons/MobileDrawer';
import { Button } from '@crayons/Button';

const OverflowIcon = () => (
  <svg width="24" height="24" xmlns="http://www.w3.org/2000/svg">
    <path
      fill-rule="evenodd"
      clip-rule="evenodd"
      d="M7 12a2 2 0 11-4 0 2 2 0 014 0zm7 0a2 2 0 11-4 0 2 2 0 014 0zm5 2a2 2 0 100-4 2 2 0 000 4z"
    />
  </svg>
);

const CheckIcon = () => (
  <svg
    aria-hidden="true"
    className="check-icon"
    fill="currentColor"
    width="24"
    height="24"
    viewBox="0 0 24 24"
    xmlns="http://www.w3.org/2000/svg"
  >
    <path d="M10 15.172l9.192-9.193 1.415 1.414L10 18l-6.364-6.364 1.414-1.414 4.95 4.95z" />
  </svg>
);

export const MobileDrawerNavigation = ({
  headingComponent,
  navigationTitle,
  navigationLinks,
}) => {
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const currentPage = navigationLinks.find((item) => item.isCurrentPage);

  const Heading = headingComponent;

  return (
    <Fragment>
      <div className="flex justify-between">
        <Heading>{currentPage.displayName}</Heading>
        <Button
          aria-label={navigationTitle}
          icon={OverflowIcon}
          size="s"
          contentType="icon"
          variant="ghost"
          onClick={() => setIsDrawerOpen(true)}
        />
      </div>

      {isDrawerOpen && (
        <MobileDrawer
          title={navigationTitle}
          onClose={() => setIsDrawerOpen(false)}
        >
          <nav aria-label={navigationTitle} className="drawer-navigation">
            <ul className="list-none">
              {navigationLinks.map((linkDetails) => (
                <li
                  key={`link-${linkDetails.url}`}
                  className="drawer-navigation__item py-2"
                >
                  <a
                    href={linkDetails.url}
                    aria-current={linkDetails.isCurrentPage ? 'page' : null}
                  >
                    {linkDetails.displayName}
                  </a>
                  <CheckIcon />
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
