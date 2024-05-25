# # lib/apache_age/types/company_type.rb
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
