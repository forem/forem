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
  const inputRef = useRef(null);

  const [emails, setEmails] = useState(['dummy']);

  const handleBlur = ({ target: { value } }) => {
    addToList(value);
    clearSelection();
  };

  const addToList = (value) => {
    setEmails([...emails, value]);
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
    const newArr = emails.filter((item) => item !== clickedItem);
    setEmails(newArr);
  };

  const clearSelection = () => {
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
          class="c-pill c-pill--action-icon c-pill--action-icon--destructive"
          type="button"
          aria-disabled="false"
        >
          {email}
          <svg
            class="crayons-icon c-pill__action-icon"
            aria-hidden="true"
            focusable="false"
            width="18"
            height="18"
            viewBox="0 0 24 24"
            xmlns="http://www.w3.org/2000/svg"
            onClick={() => handleClick(email)}
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
