module ActiveRecordAuditable::ActsAsJson
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def acts_as_json(attribute_name) # rubocop:disable Metrics/PerceivedComplexity
      return if ActiveRecordAuditable::Audit.connection.class.name.include?("SQLite")

      validate do
        value = __send__(attribute_name)

        if value.is_a?(String)
          begin
            JSON.parse(value)
          rescue JSON::ParserError
            errors.add(attribute_name, :invalid)
          end
        end
      end

      define_method(attribute_name) do
        value = super()

        if value.is_a?(String) && value.present?
          JSON.parse(value)
        else
          value
        end
      rescue JSON::ParserError
        super()
      end

      define_method(:"#{attribute_name}=") do |new_value|
        if new_value.is_a?(Hash)
          super(JSON.generate(new_value))
        elsif new_value.is_a?(String) && new_value.blank?
          super(nil)
        else
          super(new_value)
        end
      rescue JSON::ParserError
        super(new_value)
      end
    end
  end
end
