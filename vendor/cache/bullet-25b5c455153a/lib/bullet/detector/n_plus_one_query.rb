# frozen_string_literal: true

module Bullet
  module Detector
    class NPlusOneQuery < Association
      extend Dependency
      extend StackTraceFilter

      class << self
        # executed when object.assocations is called.
        # first, it keeps this method call for object.association.
        # then, it checks if this associations call is unpreload.
        #   if it is, keeps this unpreload associations and caller.
        def call_association(object, associations)
          return unless Bullet.start?
          return unless Bullet.n_plus_one_query_enable?
          return unless object.bullet_primary_key_value
          return if inversed_objects.include?(object.bullet_key, associations)

          add_call_object_associations(object, associations)

          Bullet.debug(
            'Detector::NPlusOneQuery#call_association',
            "object: #{object.bullet_key}, associations: #{associations}"
          )
          if !excluded_stacktrace_path? && conditions_met?(object, associations)
            Bullet.debug('detect n + 1 query', "object: #{object.bullet_key}, associations: #{associations}")
            create_notification caller_in_project, object.class.to_s, associations
          end
        end

        def add_possible_objects(object_or_objects)
          return unless Bullet.start?
          return unless Bullet.n_plus_one_query_enable?

          objects = Array(object_or_objects)
          return if objects.map(&:bullet_primary_key_value).compact.empty?

          Bullet.debug(
            'Detector::NPlusOneQuery#add_possible_objects',
            "objects: #{objects.map(&:bullet_key).join(', ')}"
          )
          objects.each { |object| possible_objects.add object.bullet_key }
        end

        def add_impossible_object(object)
          return unless Bullet.start?
          return unless Bullet.n_plus_one_query_enable?
          return unless object.bullet_primary_key_value

          Bullet.debug('Detector::NPlusOneQuery#add_impossible_object', "object: #{object.bullet_key}")
          impossible_objects.add object.bullet_key
        end

        def add_inversed_object(object, association)
          return unless Bullet.start?
          return unless Bullet.n_plus_one_query_enable?
          return unless object.bullet_primary_key_value

          Bullet.debug(
            'Detector::NPlusOneQuery#add_inversed_object',
            "object: #{object.bullet_key}, association: #{association}"
          )
          inversed_objects.add object.bullet_key, association
        end

        # decide whether the object.associations is unpreloaded or not.
        def conditions_met?(object, associations)
          possible?(object) && !impossible?(object) && !association?(object, associations)
        end

        def possible?(object)
          possible_objects.include? object.bullet_key
        end

        def impossible?(object)
          impossible_objects.include? object.bullet_key
        end

        # check if object => associations already exists in object_associations.
        def association?(object, associations)
          value = object_associations[object.bullet_key]
          value&.each do |v|
            # associations == v comparison order is important here because
            # v variable might be a squeel node where :== method is redefined,
            # so it does not compare values at all and return unexpected results
            result =
              v.is_a?(Hash) ? v.key?(associations) : associations == v
            return true if result
          end

          false
        end

        private

        def create_notification(callers, klazz, associations)
          notify_associations = Array(associations) - Bullet.get_whitelist_associations(:n_plus_one_query, klazz)

          if notify_associations.present?
            notice = Bullet::Notification::NPlusOneQuery.new(callers, klazz, notify_associations)
            Bullet.notification_collector.add(notice)
          end
        end
      end
    end
  end
end
