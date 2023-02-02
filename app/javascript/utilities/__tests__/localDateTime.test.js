import {timestampToLocalDateTime } from '@utilities/localDateTime';

describe('LocalDateTime Utilities', () => {
    it('should return empty string when no timestamp', () => {
     const localTime = timestampToLocalDateTime(null, null, null)
      expect(localTime).toEqual('');
    });

    it('should return readable date string', () => {
        const localTime = timestampToLocalDateTime('2019-05-03T16:02:50.908Z', 'default', {})
         expect(localTime).toEqual('5/3/2019');
       });
  });
  