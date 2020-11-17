import { render as preactRender } from 'preact';
import { unmountComponentAtNode } from 'preact/compat';

/**
 * Renders a Preact component into the given parent DOM element.
 *
 * Note: This function is calling Preact's render under the hood along with
 * a call to InstantClick's change event that explicitly unmounts the component rendered.
 *
 * @param {ComponentChild} vnode
 * @param {Element | Document | ShadowRoot | DocumentFragment} parent
 * @param {Element | Text} replaceNode
 */
export function render(vnode, parent, replaceNode) {
  InstantClick.on('change', () => {
    parent && unmountComponentAtNode(parent);
  });

  preactRender(vnode, parent, replaceNode);
}
