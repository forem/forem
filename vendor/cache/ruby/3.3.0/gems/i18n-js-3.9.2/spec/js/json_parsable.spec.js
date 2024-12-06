describe("JSON.parse", function () {
  it('should parse', function () {
    expect(JSON.parse('{"a":"Test\'s"}')).toEqual({
      a: "Test's"
    })

    expect(JSON.parse('{"a":"say \\"hello\\""}')).toEqual({
      a: 'say "hello"'
    });
    expect(JSON.parse('{"double-backslash-in-double-quote":"\\"\\\\\\\\\\""}')).toEqual({
      'double-backslash-in-double-quote': '"\\\\"'
    });
  })
})
