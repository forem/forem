import { h, Fragment } from 'preact';
import { useRef, useState } from 'preact/hooks';

const KEYS = {
  ENTER: 'Enter',
  COMMA: ',',
  SPACE: ' ',
};
// TODO: think about how this may change based on
// a different usage. We will most likely want this to be passed in as a prop.
const ALLOWED_CHARS_REGEX = /([a-zA-Z0-9@.])/;

/**
 * Component allowing users to add multiple entries for a given input field that get displayed as destructive pills
 *
 * @param {Object} props
 * @param {string} props.placeholder Input placeholder text
 */

export const MultiInput = ({ placeholder }) => {
  const inputRef = useRef(null);
  const [items, setItems] = useState([]);

  const handleBlur = ({ target: { value } }) => {
    addItemToList(value);
    clearSelection();
  };

  const handleKeyDown = (e) => {
    switch (e.key) {
      case KEYS.SPACE:
      case KEYS.ENTER:
      case KEYS.COMMA:
        e.preventDefault();
        addItemToList(e.target.value);
        clearSelection();
        break;
      default:
        if (!ALLOWED_CHARS_REGEX.test(e.key)) {
          e.preventDefault();
        }
    }
  };

  const handleDestructiveClick = (clickedItem) => {
    const newArr = items.filter((item) => item !== clickedItem);
    setItems(newArr);
  };

  const addItemToList = (value) => {
    // TODO: we will want to do some validation here based on a prop
    if (value.trim().length > 0) {
      setItems([...items, value]);
    }
  };

  const clearSelection = () => {
    inputRef.current.value = '';
  };

  const listItems = items.map((item, index) => (
    <li
      key={index}
      class="c-input--multi__selection-list-item w-max"
      style="order: 1;"
    >
      <div role="group" aria-label="two" class="flex mr-1 mb-1 w-max">
        <button
          class="c-pill c-pill--action-icon c-pill--action-icon--destructive"
          type="button"
        >
          {item}
          <svg
            class="crayons-icon c-pill__action-icon"
            aria-hidden="true"
            focusable="false"
            width="18"
            height="18"
            viewBox="0 0 24 24"
            xmlns="http://www.w3.org/2000/svg"
            onClick={() => handleDestructiveClick(item)}
          >
            <path d="m12 10.586 4.95-4.95 1.414 1.414-4.95 4.95 4.95 4.95-1.414 1.414-4.95-4.95-4.95 4.95-1.414-1.414 4.95-4.95-4.95-4.95L7.05 5.636l4.95 4.95z" />
          </svg>
        </button>
      </div>
    </li>
  ));

  return (
    <Fragment>
      <div class="c-input--multi relative">
        <div class="c-input--multi__wrapper-border crayons-textfield flex items-center cursor-text pb-9">
          <ul class="list-none flex flex-wrap w-100">
            {listItems}
            <li class="self-center" style="order: 3;">
              <input
                autocomplete="off"
                class="c-input--multi__input"
                type="text"
                onBlur={handleBlur}
                onKeyDown={handleKeyDown}
                placeholder={placeholder}
                ref={inputRef}
              />
            </li>
          </ul>
        </div>
      </div>
    </Fragment>
  );
};
