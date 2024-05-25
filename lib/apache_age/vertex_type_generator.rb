# module ApacheAge
#   module VertexTypeGenerator
#     def self.create_type_for(klass)
#       Class.new(ActiveModel::Type::Value) do
#         define_method(:cast) do |value|
#           case value
#           when klass
#             value
#           when Hash
#             klass.new(value)
#           else
#             nil
#           end
#         end

#         define_method(:serialize) do |value|
#           value.is_a?(klass) ? value.attributes : nil
#         end
#       end
#     end
#   end
# end
