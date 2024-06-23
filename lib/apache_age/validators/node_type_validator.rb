module ApacheAge
  module NodeTypeValidator
    def
      # Register the AGE typesvertex_attribute(attribute_name, type_symbol, klass)
      attribute attribute_name, type_symbol

      validate do
        value = send(attribute_name)
        unless value.is_a?(klass)
          errors.add(attribute_name, "must be a #{klass.name}")
        end
      end
    end
  end
end
