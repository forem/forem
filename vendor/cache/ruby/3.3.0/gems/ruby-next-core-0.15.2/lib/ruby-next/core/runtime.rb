# frozen_string_literal: true

# Extend `Language.transform` to inject `using RubyNext` to every file
RubyNext::Language.singleton_class.prepend(Module.new do
  def transform(contents, using: true, **hargs)
    # We cannot activate refinements in eval
    new_contents = RubyNext::Core.inject!(contents) if using
    super(new_contents || contents, using: using, **hargs)
  end
end)
