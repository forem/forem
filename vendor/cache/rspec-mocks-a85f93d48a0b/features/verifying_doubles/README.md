Verifying doubles are a stricter alternative to [normal doubles](./basics/test-doubles) that provide guarantees about
what is being verified. When using verifying doubles, RSpec will check that the methods
being stubbed are actually present on the underlying object if it is available. Prefer using
verifying doubles over normal doubles.

No checking will happen if the underlying object or class is not defined, but when run with
it present (either as a full spec run or by explicitly preloading collaborators) a failure will be
triggered if an invalid method is being stubbed or a method is called with an invalid
number of arguments.

This dual approach allows you to move very quickly and test components in isolation, while
giving you confidence that your doubles are not a complete fiction. Testing in isolation is
optional but recommended for classes that do not depend on third-party components.
