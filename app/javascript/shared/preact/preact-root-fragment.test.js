import { h } from 'preact';
import '@testing-library/jest-dom';

import { createRootFragment } from './preact-root-fragment';

describe('createRootFragment', () => {
  it('has a child element as replace node', () => {
    const fragment = createRootFragment(
      <div className="parent"></div>,
      <article>text</article>,
    );

    expect(fragment.firstChild.type).toBe('article');
  });

  it('handle multiple nodes', () => {
    const fragment = createRootFragment(<div className="parent"></div>, [
      <div id="app1"></div>,
      <div id="app2"></div>,
    ]);

    expect(fragment.firstChild.props.id).toBe('app1');
    expect(fragment.childNodes.length).toBe(2);
  });

  it('adds fragment to parent context', () => {
    const parent = <div className="parent"></div>;
    const placeholder = <div className="appXYZ"></div>;

    const fragment = createRootFragment(parent, placeholder);

    expect(parent.__k.firstChild).toBe(fragment.firstChild);
    expect(parent.__k.childNodes.length).toBeGreaterThan(0);
  });
});
