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
        <label id="multi-input-label" className="">
          Example multi input
        </label>

        <div class="c-input--multi relative">
          <div class="c-input--multi__wrapper-border crayons-textfield flex items-center cursor-text">
            <ul class="list-none flex flex-wrap w-100">
              <li
                class="c-input--multi__selection-list-item w-max"
                style="order: 1;"
              >
                <div role="group" aria-label="two" class="flex mr-1 mb-1 w-max">
                  <button
                    type="button"
                    class="c-btn c-input--multi__selected p-1 cursor-text"
                    aria-label="Edit two"
                  >
                    two
                  </button>
                  <button
                    type="button"
                    class="c-btn c-input--multi__selected p-1"
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
                  class="c-input--multi__input"
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
