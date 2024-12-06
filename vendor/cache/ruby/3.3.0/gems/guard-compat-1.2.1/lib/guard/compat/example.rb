# NOTE: Do NOT require "guard/plugin" - it will either be already required, or
# a stub will be supplied by the test class

module Guard
  class MyPlugin < Plugin
    def start
      Guard::Compat::UI.notify('foo')
      Guard::Compat::UI.color('foo')

      Guard::Compat::UI.info('foo')
      Guard::Compat::UI.warning('foo')
      Guard::Compat::UI.error('foo')
      Guard::Compat::UI.debug('foo')
      Guard::Compat::UI.deprecation('foo')
    end

    def run_all
      Guard::Compat::UI.notify('foo', bar: :baz)
      Guard::Compat::UI.color('foo', :white)

      Guard::Compat::UI.info('foo', bar: :baz)
      Guard::Compat::UI.warning('foo', bar: :baz)
      Guard::Compat::UI.error('foo', bar: :baz)
      Guard::Compat::UI.debug('foo', bar: :baz)
      Guard::Compat::UI.deprecation('foo', bar: :baz)
    end

    def run_on_modifications
      Guard::Compat::UI.color_enabled?
      Guard::Compat.matching_files(self, ['foo'])
      Guard::Compat.watched_directories
    end
  end
end
