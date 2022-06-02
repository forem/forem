/* eslint-disable jsx-a11y/interactive-supports-focus, jsx-a11y/role-has-required-aria-props */
// Disabled due to the linter being out of date for combobox role: https://github.com/jsx-eslint/eslint-plugin-jsx-a11y/issues/789
import { h, Fragment } from 'preact';

export const MultiInput = ({}) => {
  return (
    <Fragment>
      <div>
        <span
          aria-hidden="true"
          class="absolute pointer-events-none opacity-0 p-2"
        />
        {/* to fix */}
        {/* eslint-disable-next-line jsx-a11y/label-has-associated-control */}
        <label id="multi-select-label" className="">
          Example multi select autocomplete
        </label>
        <span id="input-description" class="screen-reader-only">
          Maximum 4 selections
        </span>

        <div class="screen-reader-only">
          <p>Selected items:</p>
          <ul
            className="screen-reader-only list-none"
            aria-live="assertive"
            aria-atomic="false"
            aria-relevant="additions removals"
          >
            <li>two</li>
            <li>three</li>
          </ul>
        </div>

        <div class="c-autocomplete--multi relative">
          <div class="c-autocomplete--multi__wrapper-border crayons-textfield flex items-center cursor-text">
            <ul id="combo-selected" class="list-none flex flex-wrap w-100">
              <li
                class="c-autocomplete--multi__selection-list-item w-max"
                style="order: 1;"
              >
                <div role="group" aria-label="two" class="flex mr-1 mb-1 w-max">
                  <button
                    type="button"
                    class="c-btn c-autocomplete--multi__selected p-1 cursor-text"
                    aria-label="Edit two"
                  >
                    two
                  </button>
                  <button
                    type="button"
                    class="c-btn c-autocomplete--multi__selected p-1"
                    aria-label="Remove two"
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
              <li class="self-center" style="order: 3;">
                <input
                  autocomplete="off"
                  class="c-autocomplete--multi__input"
                  aria-autocomplete="list"
                  aria-labelledby="multi-select-label selected-items-list"
                  aria-describedby="input-description"
                  aria-disabled="false"
                  type="text"
                  placeholder="Add another..."
                />
              </li>
            </ul>
          </div>
        </div>
      </div>
    </Fragment>
  );
};
