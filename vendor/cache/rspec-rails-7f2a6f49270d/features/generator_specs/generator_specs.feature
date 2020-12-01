Feature: Generator spec

    RSpec spec(s) can be generated when generating application components. For instance, `rails generate model` will also generate an RSpec spec file for the model but you can also write your own generator. See [customizing your workflow](https://guides.rubyonrails.org/generators.html#customizing-your-workflow)

    Scenario: Use custom generator
        When I run `bundle exec rails generate generator my_generator`
        Then the features should pass
        Then the output should contain:
          """
                create  lib/generators/my_generator
                create  lib/generators/my_generator/my_generator_generator.rb
                create  lib/generators/my_generator/USAGE
                create  lib/generators/my_generator/templates
                invoke  rspec
                create    spec/generator/my_generators_generator_spec.rb
          """
