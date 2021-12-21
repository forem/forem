import { h, Fragment } from 'preact';
import { useState } from 'preact/hooks';
import PropTypes from 'prop-types';
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

/**
 * Renders a page heading with a button which activates a <MobileDrawer /> with a list of the given navigation links.
 *
 * @param {object} props
 * @param {number} headingLevel The level of heading to render as the page title (e.g. 1-6)
 * @param {string} navigationTitle The title to be used for the navigation element (e.g. 'Feed timeframes')
 * @param {Array} navigationLinks An array of navigationLink objects to display
 *
 * @example
 * <MobileDrawerNavigation
 *   headingLevel={2}
 *   navigationTitle="Feed options"
 *   navigationLinks={links} />
 */
export const MobileDrawerNavigation = ({
  headingLevel,
  navigationTitle,
  navigationLinks,
}) => {
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const currentPage = navigationLinks.find((item) => item.isCurrentPage);

  const Heading = `h${headingLevel}`;

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
              {navigationLinks.map((linkDetails) => {
                const { url, isCurrentPage, displayName } = linkDetails;
                return (
                  <li
                    key={`link-${url}`}
                    className="drawer-navigation__item py-2"
                  >
                    <a href={url} aria-current={isCurrentPage ? 'page' : null}>
                      {displayName}
                    </a>
                    <CheckIcon />
                  </li>
                );
              })}
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

MobileDrawerNavigation.propTypes = {
  headingLevel: PropTypes.oneOf([1, 2, 3, 4, 5, 6]).isRequired,
  navigationTitle: PropTypes.string.isRequired,
  navigationLinks: PropTypes.arrayOf(
    PropTypes.shape({
      url: PropTypes.string,
      isCurrentPage: PropTypes.bool,
      displayName: PropTypes.string,
    }),
  ).isRequired,
};
