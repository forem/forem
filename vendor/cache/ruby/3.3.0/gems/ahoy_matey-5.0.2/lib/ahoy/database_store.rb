module Ahoy
  class DatabaseStore < BaseStore
    def track_visit(data)
      @visit = visit_model.create!(slice_data(visit_model, data))
    rescue => e
      raise e unless unique_exception?(e)

      # so next call to visit will try to fetch from DB
      if defined?(@visit)
        remove_instance_variable(:@visit)
      end
    end

    def track_event(data)
      visit = visit_or_create(started_at: data[:time])
      if visit
        event = event_model.new(slice_data(event_model, data))
        event.visit = visit
        event.time = visit.started_at if event.time < visit.started_at
        begin
          event.save!
        rescue => e
          raise e unless unique_exception?(e)
        end
      else
        Ahoy.log "Event excluded since visit not created: #{data[:visit_token]}"
      end
    end

    def geocode(data)
      visit_token = data.delete(:visit_token)
      data = slice_data(visit_model, data)
      if defined?(Mongoid::Document) && visit_model < Mongoid::Document
        # upsert since visit might not be found due to eventual consistency
        visit_model.where(visit_token: visit_token).find_one_and_update({"$set": data}, {upsert: true})
      elsif visit
        visit.update!(data)
      else
        Ahoy.log "Visit for geocode not found: #{visit_token}"
      end
    end

    def authenticate(_)
      if visit && visit.respond_to?(:user) && !visit.user
        begin
          visit.user = user
          visit.save!
        rescue ActiveRecord::AssociationTypeMismatch
          # do nothing
        end
      end
    end

    def visit
      unless defined?(@visit)
        if ahoy.send(:existing_visit_token) || ahoy.instance_variable_get(:@visit_token)
          # find_by raises error by default with Mongoid when not found
          @visit = visit_model.where(visit_token: ahoy.visit_token).take if ahoy.visit_token
        elsif !Ahoy.cookies? && ahoy.visitor_token
          @visit = visit_model.where(visitor_token: ahoy.visitor_token).where(started_at: Ahoy.visit_duration.ago..).order(started_at: :desc).first
        else
          @visit = nil
        end
      end
      @visit
    end

    # if we don't have a visit, let's try to create one first
    def visit_or_create(started_at: nil)
      ahoy.track_visit(started_at: started_at) if !visit && Ahoy.server_side_visits
      visit
    end

    protected

    def visit_model
      ::Ahoy::Visit
    end

    def event_model
      ::Ahoy::Event
    end

    def slice_data(model, data)
      column_names = model.try(:column_names) || model.attribute_names
      data.slice(*column_names.map(&:to_sym)).select { |_, v| !v.nil? }
    end

    def unique_exception?(e)
      return true if defined?(ActiveRecord::RecordNotUnique) && e.is_a?(ActiveRecord::RecordNotUnique)
      return true if defined?(PG::UniqueViolation) && e.is_a?(PG::UniqueViolation)
      return true if defined?(Mongo::Error::OperationFailure) && e.is_a?(Mongo::Error::OperationFailure) && e.message.include?("duplicate key error")
      false
    end
  end
end
