# # lib/apache_age/types/vertex_type.rb
# module ApacheAge
#   module Types
#     class VertexType < ActiveModel::Type::Value
#       def cast(value)
#         case value
#         when ApacheAge::Vertex
#           value
#         when Hash
#           ApacheAge::Vertex.new(value)
#         else
#           nil
#         end
#       end

#       def serialize(value)
#         value.is_a?(ApacheAge::Vertex) ? value.attributes : nil
#       end
#     end
#   end
# end
