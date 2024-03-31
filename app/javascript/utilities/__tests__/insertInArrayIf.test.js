import { insertInArrayIf } from '@utilities/insertInArrayIf';

describe('insertInArrayIf Utility', () => {
  it('should return insert into the array based on what the condition evaluates to', () => {
    const trueCondition = true;
    const falseCondition = false;
    const object = { a: 1, b: 1 };

    expect(insertInArrayIf(trueCondition, object)).toEqual([object]);
    expect(insertInArrayIf(falseCondition, object)).toEqual([]);
  });
});
