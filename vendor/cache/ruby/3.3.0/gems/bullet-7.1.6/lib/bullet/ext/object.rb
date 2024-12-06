# frozen_string_literal: true

class Object
  def bullet_key
    "#{self.class}:#{bullet_primary_key_value}"
  end

  def bullet_primary_key_value
    return if respond_to?(:persisted?) && !persisted?

    if self.class.respond_to?(:primary_keys) && self.class.primary_keys
      primary_key = self.class.primary_keys
    elsif self.class.respond_to?(:primary_key) && self.class.primary_key
      primary_key = self.class.primary_key
    else
      primary_key = :id
    end

    bullet_join_potential_composite_primary_key(primary_key)
  end

  private

  def bullet_join_potential_composite_primary_key(primary_keys)
    return send(primary_keys) unless primary_keys.is_a?(Enumerable)

    primary_keys.map { |primary_key| send primary_key }
                .join(',')
  end
end
