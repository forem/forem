# frozen_string_literal: true

module Bullet
  def self.collected_notifications_of_class(notification_class)
    Bullet.notification_collector.collection.select { |notification| notification.is_a? notification_class }
  end

  def self.collected_counter_cache_notifications
    collected_notifications_of_class Bullet::Notification::CounterCache
  end

  def self.collected_n_plus_one_query_notifications
    collected_notifications_of_class Bullet::Notification::NPlusOneQuery
  end

  def self.collected_unused_eager_association_notifications
    collected_notifications_of_class Bullet::Notification::UnusedEagerLoading
  end
end

module Bullet
  module Detector
    class Association
      class << self
        # returns true if all associations are preloaded
        def completely_preloading_associations?
          Bullet.collected_n_plus_one_query_notifications.empty?
        end

        def has_unused_preload_associations?
          Bullet.collected_unused_eager_association_notifications.present?
        end

        # returns true if a given object has a specific association
        def creating_object_association_for?(object, association)
          object_associations[object.bullet_key].present? &&
            object_associations[object.bullet_key].include?(association)
        end

        # returns true if a given class includes the specific unpreloaded association
        def detecting_unpreloaded_association_for?(klass, association)
          Bullet.collected_n_plus_one_query_notifications.select do |notification|
            notification.base_class == klass.to_s && notification.associations.include?(association)
          end.present?
        end

        # returns true if the given class includes the specific unused preloaded association
        def unused_preload_associations_for?(klass, association)
          Bullet.collected_unused_eager_association_notifications.select do |notification|
            notification.base_class == klass.to_s && notification.associations.include?(association)
          end.present?
        end
      end
    end
  end
end
