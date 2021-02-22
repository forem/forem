import { matchesDataTransferType } from '../pasteImageHelpers';

describe('pasteImageHelpers', () => {
  describe('matchesDataTransferType', () => {
    it('returns false if no types are provided', () => {
      expect(matchesDataTransferType([])).toBe(false);
    });

    it('returns true if at least one type matches Files', () => {
      const result = matchesDataTransferType(['example', 'Files', 'other']);
      expect(result).toBe(true);
    });

    it('returns false if no types match type Files', () => {
      const result = matchesDataTransferType(['example', 'other']);
      expect(result).toBe(false);
    });

    it('returns true if at least one type matches a custom type provided', () => {
      const result = matchesDataTransferType(['example', 'other'], 'other');
      expect(result).toBe(true);
    });

    it('returns false if no types match a custom type provided', () => {
      const result = matchesDataTransferType(['example', 'Files'], 'other');
      expect(result).toBe(false);
    });
  });
});
