import PropTypes from 'prop-types';
import { useMediaQuery } from './useMediaQuery';

/**
 * A component for evaluating whether or not a CSS media query is matched or not.
 *
 * @param {object} props
 * @param {string} props.query The media query to run.
 * @param {function} props.render A render prop for using the result of the media query.
 *
 * @return {JSX.Element} Runs the render prop function to generate a JSX element
 *
 * @example
 * import { MediaQuery } from '@components/MediaQuery';
 *
 * <MediaQuery
 *   query={`(width >= ${BREAKPOINTS.Medium}px)`}
 *   render={(matches) => {
 *     return (
 *       matches && (
 *         <aside className="crayons-layout__sidebar-left">
 *           <TagList
 *             availableTags={availableTags}
 *             selectedTag={selectedTag}
 *             onSelectTag={this.toggleTag}
 *           />
 *         </aside>
 *       )
 *     );
 *   }}
 * />
 */
export function MediaQuery({ query, render }) {
  const matchesBreakpoint = useMediaQuery(query);

  return render(matchesBreakpoint);
}

MediaQuery.propTypes = {
  query: PropTypes.string.isRequired,
  render: PropTypes.func.isRequired,
};
