When [allowing](./basics/allowing-messages) or [expecting](./basics/expecting-messages) messages, the default response is to return `nil`. Several
methods are provided to configure how the test double responds to the message.

* <a href="./configuring-responses/returning-a-value">`and_return`</a>
* <a href="./configuring-responses/raising-an-error">`and_raise`</a>
* <a href="./configuring-responses/mixed-responses">`and_invoke`</a>
* <a href="./configuring-responses/throwing">`and_throw`</a>
* <a href="./configuring-responses/yielding">`and_yield`</a>
* <a href="./configuring-responses/calling-the-original-implementation">`and_call_original`</a>
* <a href="./configuring-responses/wrapping-the-original-implementation">`and_wrap_original`</a>

In addition, you can provide a [block implementation](./configuring-responses/block-implementation) to respond in any manner you wish.

Note: for simplicity, the examples here use `allow` rather than `expect`, but these APIs apply equally to both cases.
