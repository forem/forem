import { render as preactRender } from 'preact';
import { unmountComponentAtNode } from 'preact/compat';

/**
 * Renders a Preact component into the given parent DOM element.
 *
 * Note: This function is calling Preact's render under the hood along with
 * a call to InstantClick's change event that explicitly unmounts the component rendered.
 *
 * @param {object} vnode The virtual DOM node representing a component.
 * @param {Element | Document | ShadowRoot | DocumentFragment} parent The DOM element where the component will render.
 * @param {Element | Text} replaceNode An optional DOM element that must of the given parent.
 * Instead of inferring where to start rendering, it will update or replace the passed element using Preact's diffing algorithm.
 */
export function render(vnode, parent, replaceNode) {
  InstantClick.on('change', () => {
    // We need to explicitly unmount a Preact component since we are using InstantClick. Failing to do so
    // would leave references to past components.
    parent && unmountComponentAtNode(parent);
  });

  preactRender(vnode, parent, replaceNode);
}
