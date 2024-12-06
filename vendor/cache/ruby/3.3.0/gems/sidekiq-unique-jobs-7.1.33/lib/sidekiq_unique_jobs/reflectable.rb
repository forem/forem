# frozen_string_literal: true

module SidekiqUniqueJobs
  #
  # Module Reflectable provides a method to notify subscribers
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  #
  module Reflectable
    #
    # Reflects on specific event
    #
    # @param [Symbol] reflection the reflected event
    # @param [Array] args arguments to provide to reflector
    #
    # @return [void]
    #
    def reflect(reflection, *args)
      SidekiqUniqueJobs.reflections.dispatch(reflection, *args)
      nil
    rescue UniqueJobsError => ex
      SidekiqUniqueJobs.logger.error(ex)
      nil
    end
  end
end
