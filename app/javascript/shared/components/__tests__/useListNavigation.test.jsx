import '@testing-library/jest-dom';
import { fireEvent } from '@testing-library/preact';
import { renderHook } from '@testing-library/preact-hooks';
import { useListNavigation } from '../useListNavigation';

const NAVIGATION_UP_KEY = 'KeyK';
const NAVIGATION_DOWN_KEY = 'KeyJ';

describe('List navigation hook', () => {
  beforeAll(() => {
    window.scrollTo = function () {};
  });

  it('should focus on first element when nothing is focused', () => {
    document.body.innerHTML = `
      <div>
        <article class="container">
          <a href="/" class="focusable" id="focusable-1">link</a>
        </article>
        <article class="container">
          <a href="/" class="focusable" id="focusable-2">link</a>
        </article>
      </div>
    `;

    renderHook(() => useListNavigation('article.container', 'a.focusable'));

    const firstFocusable = document.querySelector('#focusable-1');

    fireEvent.keyDown(document, { code: NAVIGATION_DOWN_KEY });

    expect(firstFocusable).toHaveFocus();
  });

  it('should focus on immediate previous focusable on up key', () => {
    document.body.innerHTML = `
      <div>
        <article class="container">
          <a href="/" class="focusable" id="focusable-1">link</a>
        </article>
        <article class="container">
          <a href="/" class="focusable" id="focusable-2">link</a>
        </article>
      </div>
    `;

    renderHook(() => useListNavigation('article.container', 'a.focusable'));

    const firstFocusable = document.querySelector('#focusable-1');
    const secondFocusable = document.querySelector('#focusable-2');

    secondFocusable.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_UP_KEY });

    expect(firstFocusable).toHaveFocus();
  });

  it('should focus on immediate next focusable on down key', () => {
    document.body.innerHTML = `
      <div>
        <article class="container">
          <a href="/" class="focusable" id="focusable-1">link</a>
        </article>
        <article class="container">
          <a href="/" class="focusable" id="focusable-2">link</a>
        </article>
      </div>
    `;

    renderHook(() => useListNavigation('article.container', 'a.focusable'));

    const firstFocusable = document.querySelector('#focusable-1');
    const secondFocusable = document.querySelector('#focusable-2');

    firstFocusable.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_DOWN_KEY });

    expect(secondFocusable).toHaveFocus();
  });

  it('should keep focus on up key when the start of the list is reached', () => {
    document.body.innerHTML = `
      <div>
        <article class="container">
          <a href="/" class="focusable" id="focusable-1">link</a>
        </article>
        <article class="container">
          <a href="/" class="focusable" id="focusable-2">link</a>
        </article>
      </div>
    `;

    renderHook(() => useListNavigation('article.container', 'a.focusable'));

    const firstFocusable = document.querySelector('#focusable-1');
    const secondFocusable = document.querySelector('#focusable-2');

    secondFocusable.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_UP_KEY });
    expect(firstFocusable).toHaveFocus();

    // focus is already at the start of the list
    fireEvent.keyDown(document, { code: NAVIGATION_UP_KEY });
    expect(firstFocusable).toHaveFocus();
  });

  it('should keep focus on down key when the bottom of the list is reached', () => {
    document.body.innerHTML = `
      <div>
        <article class="container">
          <a href="/" class="focusable" id="focusable-1">link</a>
        </article>
        <article class="container">
          <a href="/" class="focusable" id="focusable-2">link</a>
        </article>
      </div>
    `;

    renderHook(() => useListNavigation('article.container', 'a.focusable'));

    const firstFocusable = document.querySelector('#focusable-1');
    const secondFocusable = document.querySelector('#focusable-2');

    firstFocusable.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_DOWN_KEY });
    expect(secondFocusable).toHaveFocus();

    // focus is already at the bottom of the list
    fireEvent.keyDown(document, { code: NAVIGATION_DOWN_KEY });
    expect(secondFocusable).toHaveFocus();
  });

  it('should focus on previous element before waterfall container on up key', () => {
    document.body.innerHTML = `
      <div>
        <article class="container">
          <a href="/" class="focusable" id="focusable-1">link</a>
        </article>
        <div class="waterfall">
          <article class="container">
            <a href="/" class="focusable" id="focusable-2">link</a>
          </article>
        </div>
      </div>
    `;

    renderHook(() =>
      useListNavigation('article.container', 'a.focusable', 'div.waterfall'),
    );

    const firstFocusable = document.querySelector('#focusable-1');
    const secondFocusable = document.querySelector('#focusable-2');

    secondFocusable.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_UP_KEY });

    expect(firstFocusable).toHaveFocus();
  });

  it('should focus on next element inside waterfall container on down key', () => {
    document.body.innerHTML = `
      <div>
        <article class="container">
          <a href="/" class="focusable" id="focusable-1">link</a>
        </article>
        <div class="waterfall">
          <article class="container">
            <a href="/" class="focusable" id="focusable-2">link</a>
          </article>
        </div>
      </div>
    `;

    renderHook(() =>
      useListNavigation('article.container', 'a.focusable', 'div.waterfall'),
    );

    const firstFocusable = document.querySelector('#focusable-1');
    const secondFocusable = document.querySelector('#focusable-2');

    firstFocusable.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_DOWN_KEY });

    expect(secondFocusable).toHaveFocus();
  });

  it('should focus on previous element on up key when an unrelated element is between 2 relevant elements', async () => {
    document.body.innerHTML = `
      <div>
        <article class="container">
          <a href="/" class="focusable" id="focusable-1">link</a>
        </article>
        <article class="unrelated">
          <a href="/" class="unrelated-focusable" id="unrelated-focusable">link</a>
        </article>
        <article class="container">
          <a href="/" class="focusable" id="focusable-2">link</a>
        </article>
      </div>
    `;

    renderHook(() => useListNavigation('article.container', 'a.focusable'));

    const firstFocusable = document.querySelector('#focusable-1');
    const secondFocusable = document.querySelector('#focusable-2');

    secondFocusable.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_UP_KEY });

    expect(firstFocusable).toHaveFocus();
  });

  it('should focus on next element on down key when an unrelated element is between 2 relevant elements', () => {
    document.body.innerHTML = `
      <div>
        <article class="container">
          <a href="/" class="focusable" id="focusable-1">link</a>
        </article>
        <article class="unrelated">
          <a href="/" class="unrelated-focusable">link</a>
        </article>
        <article class="container">
          <a href="/" class="focusable" id="focusable-2">link</a>
        </article>
      </div>
    `;

    renderHook(() => useListNavigation('article.container', 'a.focusable'));

    const firstFocusable = document.querySelector('#focusable-1');
    const secondFocusable = document.querySelector('#focusable-2');

    firstFocusable.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_DOWN_KEY });

    expect(secondFocusable).toHaveFocus();
  });

  it('should focus on previous element on up key when inner secondary element is focused', () => {
    document.body.innerHTML = `
      <div>
        <article class="container">
          <a href="/" class="focusable" id="focusable-1">link</a>
          <a href="/" id="inner-secondary-1">link</a>
        </article>
        <article class="container">
          <a href="/" class="focusable" id="focusable-2">link</a>
          <a href="/" id="inner-secondary-2">link</a>
        </article>
      </div>
    `;

    renderHook(() => useListNavigation('article.container', 'a.focusable'));

    const firstFocusable = document.querySelector('#focusable-1');
    const secondInnerSecondaryFocusable = document.querySelector(
      '#inner-secondary-2',
    );

    secondInnerSecondaryFocusable.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_UP_KEY });

    expect(firstFocusable).toHaveFocus();
  });

  it('should focus on next element on down key when inner secondary element is focused', () => {
    document.body.innerHTML = `
      <div>
        <article class="container">
          <a href="/" class="focusable" id="focusable-1">link</a>
          <a href="/" id="inner-secondary-1">link</a>
        </article>
        <article class="container">
          <a href="/" class="focusable" id="focusable-2">link</a>
          <a href="/" id="inner-secondary-2">link</a>
        </article>
      </div>
    `;

    renderHook(() => useListNavigation('article.container', 'a.focusable'));

    const firstInnerSecondaryFocusable = document.querySelector(
      '#inner-secondary-1',
    );
    const secondFocusable = document.querySelector('#focusable-2');

    firstInnerSecondaryFocusable.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_DOWN_KEY });

    expect(secondFocusable).toHaveFocus();
  });

  it('should skip previous element on up key when it is unrelated and handle waterfall', () => {
    document.body.innerHTML = `
      <div>
        <article class="container">
          <a href="/" class="focusable" id="focusable-1">link</a>
        </article>
        <article class="unrelated">
          <a href="/" class="unrelated">link</a>
        </article>
        <div class="waterfall">
          <article class="container">
            <a href="/" class="focusable" id="focusable-2">link</a>
          </article>
        </div>
      </div>
    `;

    renderHook(() =>
      useListNavigation('article.container', 'a.focusable', 'div.waterfall'),
    );

    const firstElement = document.querySelector('#focusable-1');
    const secondElement = document.querySelector('#focusable-2');

    secondElement.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_UP_KEY });

    expect(firstElement).toHaveFocus();
  });

  it('should skip next element on down key when it is unrelated and handle waterfall', () => {
    document.body.innerHTML = `
      <div>
        <article class="container">
          <a href="/" class="focusable" id="focusable-1">link</a>
        </article>
        <article class="unrelated">
          <a href="/" class="unrelated-focusable">link</a>
        </article>
        <div class="waterfall">
          <article class="container">
            <a href="/" class="focusable" id="focusable-2">link</a>
          </article>
        </div>
      </div>
    `;

    renderHook(() =>
      useListNavigation('article.container', 'a.focusable', 'div.waterfall'),
    );

    const firstElement = document.querySelector('#focusable-1');
    const secondElement = document.querySelector('#focusable-2');

    firstElement.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_DOWN_KEY });

    expect(secondElement).toHaveFocus();
  });
});
