/* eslint-disable jsx-a11y/interactive-supports-focus, jsx-a11y/role-has-required-aria-props */
// Disabled due to the linter being out of date for combobox role: https://github.com/jsx-eslint/eslint-plugin-jsx-a11y/issues/789
import { h, Fragment } from 'preact';
import { useRef, useState } from 'preact/hooks';

const KEYS = {
  ENTER: 'Enter',
  COMMA: ',',
  SPACE: ' ',
};
// TODO: think about how this may change based on
// a different usage. We may want this to be custom.
const ALLOWED_CHARS_REGEX = /([a-zA-Z0-9@.])/;

export const MultiInput = ({}) => {
  const inputSizerRef = useRef(null);
  const inputRef = useRef(null);

  const [emails, setEmails] = useState(['dummy']);

  const handleBlur = ({ target: { value } }) => {
    // When the input appears inline in "edit" mode, we need to dynamically calculate the width to ensure it occupies the right space
    // (an input cannot resize based on its text content). We use a hidden <span> to track the size.
    inputSizerRef.current.innerText = value;
    // TODO: let's deal with it at a later point
    // if (inputPosition !== null) {
    //   resizeInputToContentSize();
    // }

    addToList(value);
    clearSelection();
  };

  const addToList = (value) => {
    // The spread operator is syntactic sugar for creating a new copy of a reference.
    const dupEmails = [...emails];
    dupEmails.push(value);
    setEmails(dupEmails);

    // another wya to do it.
    // const handleAdd = (todo) => {
    // setTodos([...todos, todo]);
    // }
    // console.log(emails)
  };

  const handleKeyDown = (e) => {
    switch (e.key) {
      case KEYS.ENTER:
      case KEYS.SPACE:
      case KEYS.COMMA:
        e.preventDefault();
        // we probably want to add validation here
        addToList(e.target.value);
        clearSelection();
        break;
      default:
        if (!ALLOWED_CHARS_REGEX.test(e.key)) {
          e.preventDefault();
        }
    }
  };

  // TODO: rename email to item everywhere
  const handleClick = (clickedItem) => {
    // get the email that we're trying to remove
    // find and remove the selected item from the array
    const newArr = emails.filter((item) => item !== clickedItem);
    setEmails(newArr);
  };

  const clearSelection = () => {
    // TODO: Investigate is it better to use a ref or set state
    inputRef.current.value = '';
  };

  const listEmails = emails.map((email, index) => (
    <li
      key={index}
      class="c-input--multi__selection-list-item w-max"
      style="order: 1;"
    >
      <div role="group" aria-label="two" class="flex mr-1 mb-1 w-max">
        <button
          type="button"
          class="c-btn c-input--multi__selected p-1 cursor-text"
          aria-label="Edit two"
        >
          {email}
        </button>
        <button
          type="button"
          class="c-btn c-input--multi__selected p-1"
          aria-label="Remove two"
          onClick={() => handleClick(email)}
        >
          <svg
            class="crayons-icon"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path d="m12 10.586 4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636l4.95 4.95z" />
          </svg>
        </button>
      </div>
    </li>
  ));

  return (
    <Fragment>
      <div>
        <span
          ref={inputSizerRef}
          aria-hidden="true"
          class="absolute pointer-events-none opacity-0 p-2"
        />
        {/* TODO: */}
        {/* eslint-disable-next-line jsx-a11y/label-has-associated-control */}
        <label id="multi-input-label" className="">
          Example multi input
        </label>

        <div class="c-input--multi relative">
          <div class="c-input--multi__wrapper-border crayons-textfield flex items-center cursor-text">
            <ul class="list-none flex flex-wrap w-100">
              {listEmails}
              <li class="self-center" style="order: 3;">
                <input
                  autocomplete="off"
                  class="c-input--multi__input"
                  aria-labelledby="multi-select-label selected-items-list"
                  aria-describedby="input-description"
                  aria-disabled="false"
                  type="text"
                  onBlur={handleBlur}
                  onKeyDown={handleKeyDown}
                  placeholder="Add another..."
                  ref={inputRef}
                />
              </li>
            </ul>
          </div>
        </div>
      </div>
    </Fragment>
  );
};
