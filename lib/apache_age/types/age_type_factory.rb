# lib/apache_age/types/age_type_factory.rb
# Automatically generates ActiveModel::Type classes
# Dynamically builds this (as a concrete example):
# module ApacheAge
#   module Types
#     class CompanyType < ActiveModel::Type::Value
#       def cast(value)
#         case value
#         when Nodes::Company
#           value
#         when Hash
#           Nodes::Company.new(value)
#         else
#           nil
#         end
#       end
#       def serialize(value)
#         value.is_a?(Nodes::Company) ? value.attributes : nil
#       end
#     end
#   end
# end
module ApacheAge
  module Types
    class AgeTypeFactory
      def self.create_type_for(klass)
        Class.new(ActiveModel::Type::Value) do
          define_method(:cast) do |value|
            case value
            when klass
              value
            when Hash
              klass.new(value)
            else
              nil
            end
          end

          define_method(:serialize) do |value|
            value.is_a?(klass) ? value.attributes : nil
          end
        end
      end
    end
  end
end
