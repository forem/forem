RSpec provides a fluent interface off of `expect(...).to receive(...)` that allows you to
further constrain what you expect: the arguments, the number of times, and the ordering of
multiple messages.

Although not shown here, this fluent interface is also supported by [spies](./basics/spies), off of
`have_received(...)`.
