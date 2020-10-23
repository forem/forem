import '@testing-library/jest-dom';
import { fireEvent } from '@testing-library/preact';
import { renderHook } from '@testing-library/preact-hooks';
import { useListNavigation } from '../useListNavigation';

const NAVIGATION_UP_KEY = 'KeyK';
const NAVIGATION_DOWN_KEY = 'KeyJ';

describe('List navigation hook', () => {
  it('should focus on first element when nothing is focused', () => {
    document.body.innerHTML = `
      <div>
        <a href="/" class="element" id="element-1">link</a>
        <a href="/" class="element" id="element-2">link</a>
      </div>
    `;

    renderHook(() => useListNavigation('a.element'));

    const firstElement = document.querySelector('#element-1');

    fireEvent.keyDown(document, { code: NAVIGATION_DOWN_KEY });

    expect(firstElement).toHaveFocus();
  });

  it('should focus on immediate previous element on up key', () => {
    document.body.innerHTML = `
      <div>
        <a href="/" class="element" id="element-1">link</a>
        <a href="/" class="element" id="element-2">link</a>
      </div>
    `;

    renderHook(() => useListNavigation('a.element'));

    const firstElement = document.querySelector('#element-1');
    const secondElement = document.querySelector('#element-2');

    secondElement.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_UP_KEY });

    expect(firstElement).toHaveFocus();
  });

  it('should focus on immediate next element on down key', () => {
    document.body.innerHTML = `
      <div>
        <a href="/" class="element" id="element-1">link</a>
        <a href="/" class="element" id="element-2">link</a>
      </div>
    `;

    renderHook(() => useListNavigation('a.element'));

    const firstElement = document.querySelector('#element-1');
    const secondElement = document.querySelector('#element-2');

    firstElement.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_DOWN_KEY });

    expect(secondElement).toHaveFocus();
  });

  it('should keep focus on up key when the start of the list is reached', () => {
    document.body.innerHTML = `
      <div>
        <a href="/" class="element" id="element-1">link</a>
        <a href="/" class="element" id="element-2">link</a>
      </div>
    `;

    renderHook(() => useListNavigation('a.element'));

    const firstElement = document.querySelector('#element-1');
    const secondElement = document.querySelector('#element-2');

    secondElement.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_UP_KEY });
    expect(firstElement).toHaveFocus();

    // focus is already at the start of the list
    fireEvent.keyDown(document, { code: NAVIGATION_UP_KEY });
    expect(firstElement).toHaveFocus();
  });

  it('should keep focus on down key when the bottom of the list is reached', () => {
    document.body.innerHTML = `
      <div>
        <a href="/" class="element" id="element-1">link</a>
        <a href="/" class="element" id="element-2">link</a>
      </div>
    `;

    renderHook(() => useListNavigation('a.element'));

    const firstElement = document.querySelector('#element-1');
    const secondElement = document.querySelector('#element-2');

    firstElement.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_DOWN_KEY });
    expect(secondElement).toHaveFocus();

    // focus is already at the bottom of the list
    fireEvent.keyDown(document, { code: NAVIGATION_DOWN_KEY });
    expect(secondElement).toHaveFocus();
  });

  it('should focus on previous element before waterfall container on up key', () => {
    document.body.innerHTML = `
      <div>
        <a href="/" class="element" id="element-1">link</a>
        <div class="waterfall">
          <a href="/" class="element" id="element-2">link</a>
        </div>
      </div>
    `;

    renderHook(() => useListNavigation('a.element', 'div.waterfall'));

    const firstElement = document.querySelector('#element-1');
    const secondElement = document.querySelector('#element-2');

    secondElement.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_UP_KEY });

    expect(firstElement).toHaveFocus();
  });

  it('should focus on next element inside waterfall container on down key', () => {
    document.body.innerHTML = `
      <div>
        <a href="/" class="element" id="element-1">link</a>
        <div class="waterfall">
          <a href="/" class="element" id="element-2">link</a>
        </div>
      </div>
    `;

    renderHook(() => useListNavigation('a.element', 'div.waterfall'));

    const firstElement = document.querySelector('#element-1');
    const secondElement = document.querySelector('#element-2');

    firstElement.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_DOWN_KEY });

    expect(secondElement).toHaveFocus();
  });

  it('should skip previous element on up key when it is unrelated', async () => {
    document.body.innerHTML = `
      <div>
        <a href="/" class="element" id="element-1">link</a>
        <a href="/" class="unrelated">link</a>
        <a href="/" class="element" id="element-2">link</a>
      </div>
    `;

    renderHook(() => useListNavigation('a.element'));

    const firstElement = document.querySelector('#element-1');
    const secondElement = document.querySelector('#element-2');

    secondElement.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_UP_KEY });

    expect(firstElement).toHaveFocus();
  });

  it('should skip next element on down key when it is unrelated', () => {
    document.body.innerHTML = `
      <div>
        <a href="/" class="element" id="element-1">link</a>
        <a href="/" class="unrelated">link</a>
        <a href="/" class="element" id="element-2">link</a>
      </div>
    `;

    renderHook(() => useListNavigation('a.element'));

    const firstElement = document.querySelector('#element-1');
    const secondElement = document.querySelector('#element-2');

    firstElement.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_DOWN_KEY });

    expect(secondElement).toHaveFocus();
  });

  it('should focus on previous element on up key when inner element is focused', () => {
    document.body.innerHTML = `
      <div>
        <a href="/" class="element" id="element-1">link</a>
        <article class="element" id="element-2">
          <span>link</span>
          <a href="/" id="inner">link</a>
        </a>
      </div>
    `;

    renderHook(() => useListNavigation('.element'));

    const firstElement = document.querySelector('#element-1');
    const innerElement = document.querySelector('#inner');

    innerElement.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_UP_KEY });

    expect(firstElement).toHaveFocus();
  });

  it('should focus on next element on down key when inner element is focused', () => {
    document.body.innerHTML = `
      <div>
        <article class="element" id="element-1">
          <span>link</span>
          <a href="/" id="inner">link</a>
        </article>
        <a href="/" class="element" id="element-2">link</a>
      </div>
    `;

    renderHook(() => useListNavigation('.element'));

    const secondElement = document.querySelector('#element-2');
    const innerElement = document.querySelector('#inner');

    innerElement.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_DOWN_KEY });

    expect(secondElement).toHaveFocus();
  });

  it('should skip previous element on up key when it is unrelated and handle waterfall', () => {
    document.body.innerHTML = `
      <div>
        <a href="/" class="element" id="element-1">link</a>
        <a href="/" class="unrelated">link</a>
        <div class="waterfall">
          <a href="/" class="element" id="element-2">link</a>
        </div>
      </div>
    `;

    renderHook(() => useListNavigation('a.element', 'div.waterfall'));

    const firstElement = document.querySelector('#element-1');
    const secondElement = document.querySelector('#element-2');

    secondElement.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_UP_KEY });

    expect(firstElement).toHaveFocus();
  });

  it('should skip next element on down key when it is unrelated and handle waterfall', () => {
    document.body.innerHTML = `
      <div>
        <a href="/" class="element" id="element-1">link</a>
        <a href="/" class="unrelated">link</a>
        <div class="watefall">
          <a href="/" class="element" id="element-2">link</a>
        </div>
      </div>
    `;

    renderHook(() => useListNavigation('a.element', 'div.waterfall'));

    const firstElement = document.querySelector('#element-1');
    const secondElement = document.querySelector('#element-2');

    firstElement.focus();

    fireEvent.keyDown(document, { code: NAVIGATION_DOWN_KEY });

    expect(secondElement).toHaveFocus();
  });
});
