# frozen_string_literal: true

require 'rake'

module KnapsackPro
  class TaskLoader
    include ::Rake::DSL

    def load_tasks
      Dir.glob("#{KnapsackPro.root}/lib/tasks/**/*.rake").each { |r| import r }
    end
  end
end
