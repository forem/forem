/**
 * Helper function to merge an array of refs when attaching to a Preact component. Useful for when a ref is used by both the component itself and its parent.
 *
 * @param {Array} refs Array of all references
 *
 * @example
 * const MyComponent = forwardRef((props, forwardedRef) => {
 *  const innerRef = useRef(null);
 *  return (
 *   <InnerComponent
 *      ref={mergeRefs([forwardedRef, innerRef])}
 *   />
 *  );
 * });
 */
export const mergeRefs = (refs) => (value) => {
  refs.forEach((ref) => {
    if (ref) {
      ref.current = value;
    }
  });
};
