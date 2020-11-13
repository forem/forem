---
title: Service Objects
---

## What are Service Objects

Service objects are Plain Old Ruby Objects (POROs) which encapsulate a whole
business process/user interaction.

Our services are located in `app/services` with the corresponding specs in
`spec/services`. Their main interface is a class level method named `call`, as
in the following example:

```ruby
class ImportUsers
  def self.call(arg1)
    new(arg1).call
  end

  def initialize(arg1)
    @arg1 = arg1
  end

  def call
    # import code goes here
  end
end
```

To distinguish services from models we often give them verb names vs noun names,
e.g. `ImportUsers` instead of `UserImporter`.

## Generating Service Objects

To make our services more consistent we use a custom Rails generator. Some usage
examples:

**Generate a non-namespaced service without arguments**

`$ rails generate service DoTheThing`

```ruby
# app/services/do_the_thing.rb
class DoTheThing
  def self.call
    new.call
  end

  def call
  end
end
```

```ruby
# spec/services/do_the_thing_spec.rb
require "rails_helper"

RSpec.describe DoTheThing, type: :service do
  pending "add some examples to (or delete) #{__FILE__}"
end
```

**Generate a non-namespaced service with arguments:**

`$ rails generate service DoTheThing arg1 arg2`

```ruby
# app/services/do_the_thing.rb
class DoTheThing
  def self.call(arg1, arg2)
    new(arg1, arg2).call
  end

  def initialize(arg1, arg2)
    @arg1 = arg1
    @arg2 = arg2
  end

  def call
  end
end
```

The generated spec is the same as above.

**Generate a namespaced service with arguments**

`$ rails generate service things/dothem arg1 arg2`

```ruby
# app/services/things/do_them.rb
class Things::DoThem
  def self.call(arg1, arg2)
    new(arg1, arg2).call
  end

  def initialize(arg1, arg2)
    @arg1 = arg1
    @arg2 = arg2
  end

  def call
  end
end
```

```ruby
# spec/services/things/do_them_spec.rb
require "rails_helper"

RSpec.describe Things::DoThem, type: :service do
  pending "add some examples to (or delete) #{__FILE__}"
end
```
