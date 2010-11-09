module TripwireNotifier
  module Rails
    # This module is mixed into ActionController::Base.
    module ActionControllerMonitor

      def self.included(base)
        base.after_filter :log_validation_failures_to_tripwire, :only => [:create, :update]
      end

      protected

      def log_validation_failures_to_tripwire
        if should_log_failures_to_tripwire? && records_with_errors.present?
          TripwireNotifier.notify(tripwire_params)
        end
      end

      def should_log_failures_to_tripwire?
        TripwireNotifier.configuration.monitored_environments.include?(::Rails.env.to_s)
      end

      def records_with_errors
        @records_with_errors ||= begin
          instance_variable_names.map do |var_name|
            var = instance_variable_get(var_name)
            if var.is_a?(Array)
              var.select{|v| record_has_errors?(v)}
            else
              var if record_has_errors?(var)
            end
          end.flatten.compact
        end
      end

      def record_has_errors?(record)
        record.respond_to?(:errors) && record.errors.present?
      end

      def tripwire_params
        {}.tap do |query|
          query[:_controller]  = params['controller']
          query[:_action]      = params['action']
          query[:path]         = request.path
          query[:data]         = request_data.to_json

          query[:failures] = records_with_errors.map do |record|
            error_hashes(record)
          end.flatten.to_json
        end
      end

      def error_hashes(record)
        record.errors.map do |field, messages|
          Array.wrap(messages).map do |message|
            error_hash(record.class, field, message)
          end
        end
      end

      def error_hash(clazz, field, message)
        {
          :model   => clazz.to_s,
          :field   => field,
          :message => message
        }
      end

      def request_data
        {}.tap do |data|
          # TODO: limit this in size - how big?
          data[:params] = filtered_params # TODO: controller and action are redundant

          if respond_to?(:current_user) && !current_user.nil?
            data[:current_user] = current_user.id
          end

          data[:user_agent] = request.user_agent
          data[:cookies] = request.cookies
          data[:session] = request.session
        end
      end

      def filtered_params
        if respond_to?(:filter_parameters)
          # pre-Rails 3
          filter_parameters(params)
        elsif request.respond_to?(:filtered_parameters)
          # Rails 3
          request.filtered_parameters
        else
          params
        end
      end
    end
  end
end

ActionController::Base.send(:include, TripwireNotifier::Rails::ActionControllerMonitor)
