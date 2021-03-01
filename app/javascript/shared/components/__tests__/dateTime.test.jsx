import { h } from 'preact';
import { axe } from 'jest-axe';
import { render } from '@testing-library/preact';
import '@testing-library/jest-dom';
import { DateTime } from '../dateTime';

import '../../../../assets/javascripts/utilities/localDateTime';

/* eslint-disable no-unused-vars */
/* global globalThis timestampToLocalDateTimeLong timestampToLocalDateTimeShort */

describe('<DateTime />', () => {
  it('should have no a11y violations', async () => {
    afterAll(() => {
      delete globalThis.timestampToLocalDateTimeLong;
      delete globalThis.timestampToLocalDateTimeShort;
    });

    const { container } = render(
      <DateTime
        className={'date-time'}
        dateTime={new Date('2019-09-20T17:26:20.531Z')}
      />,
    );
    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('should render given datetime', () => {
    const { getByText } = render(
      <DateTime
        className={'date-time'}
        dateTime={new Date('2019-09-10T17:26:20.531Z')}
      />,
    );

    const dateTime = getByText('Sep 10, 2019');
    expect(dateTime.title).toBe('Tuesday, September 10, 2019, 5:26:20 PM');
    expect(dateTime).toHaveClass('date-time');
  });
});
