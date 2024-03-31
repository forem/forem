/**
 * A Preact 11+ implementation of the `replaceNode` parameter from Preact 10.
 *
 * This creates a "Persistent Fragment" (a fake DOM element) containing one or more
 * DOM nodes, which can then be passed as the `parent` argument to Preact's `render()` method.
 * Source: https://gist.github.com/developit/f4c67a2ede71dc2fab7f357f39cff28c
 */
export function createRootFragment(parent, replaceNode) {
  if (replaceNode) {
    replaceNode = Array.isArray(replaceNode) ? replaceNode : [replaceNode];
  } else {
    replaceNode = [parent];
    parent = parent.parentNode;
  }

  const s = replaceNode[replaceNode.length - 1].nextSibling;

  const rootFragment = {
    nodeType: 1,
    parentNode: parent,
    firstChild: replaceNode[0],
    childNodes: replaceNode,
    insertBefore: (c, r) => {
      parent.insertBefore(c, r || s);
      return c;
    },
    appendChild: (c) => {
      parent.insertBefore(c, s);
      return c;
    },
    removeChild: (c) => {
      parent.removeChild(c);
      return c;
    },
  };

  parent.__k = rootFragment;
  return rootFragment;
}
