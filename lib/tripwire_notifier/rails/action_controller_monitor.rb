module TripwireNotifier
  module Rails
    # This module is mixed into ActionController::Base.
    module ActionControllerMonitor

      def self.included(base)
        base.after_filter :log_validation_failures_to_tripwire, :only => [:create, :update]
      end

      protected

      def log_validation_failures_to_tripwire
        if should_log_failures_to_tripwire? && (records_with_errors.present? || flash_errors.present?)
          TripwireNotifier.notify(tripwire_params)
        end
      rescue Exception => e
        ::Rails.logger.error("Failed to log validation failure to Tripwire")

        handler = TripwireNotifier.configuration.on_exception
        handler.call(e) if !handler.nil? && handler.respond_to?(:call)
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

          query[:failures] = (flash_errors + records_with_errors.map do |record|
            error_hashes(record)
          end).flatten.compact.to_json
        end
      end

      def flash_errors
        @flash_errors ||= begin
          return [] unless session['flash']

          TripwireNotifier.configuration.monitored_flash_keys.inject([]) do |errors, key|
            if error = session['flash'][key]
              errors << error_hash('flash', 'error', error)
            end
          end
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
          data[:cookies] = stringify_values(request.cookies)
          data[:session] = stringify_values(request.session)
        end
      end

      def filtered_params
        p = if respond_to?(:filter_parameters)
          # pre-Rails 3
          filter_parameters(params)
        elsif request.respond_to?(:filtered_parameters)
          # Rails 3
          request.filtered_parameters
        else
          params
        end
        filter_files_from_params(p)
      end

      def filter_files_from_params(params)
        params.each do |k,v|
          if v.is_a?(Hash)
            filter_files_from_params(v)
          elsif v.is_a?(Tempfile)
            params[k] = '[FILTERED]'
          end
        end
      end

      def stringify_values(values)
        case values
        when Array
          values.map { |v| stringify_values(v) }
        when Hash
          Hash[values.map { |k,v| [k, stringify_values(v)] }]
        else
          values.to_s
        end
      end
    end
  end
end

ActionController::Base.send(:include, TripwireNotifier::Rails::ActionControllerMonitor)
