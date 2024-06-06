require 'rails/generators'
require 'rails/generators/named_base'

module ApacheAge
  module Generators
    class NodeGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)
      argument :attributes, type: :array, default: [], banner: "field:type field:type"

      def create_node_file
        template "node.rb.tt", File.join("app/nodes", class_path, "#{file_name}.rb")
      end

      private

      def attributes_list
        attributes.map { |attr| { name: attr.name, type: attr.type } }
      end

      def unique_attributes
        attributes_list.map { |attr| attr[:name].to_sym }
      end

      def parent_module
        class_path.map(&:camelize).join('::')
      end

      def full_class_name
        parent_module.empty? ? class_name : "#{parent_module}::#{class_name}"
      end

      def indented_namespace
        return '' if parent_module.empty?

        parent_module.split('::').map.with_index do |namespace, index|
          "#{'  ' * index}module #{namespace}"
        end.join("\n") + "\n"
      end

      def indented_end_namespace
        return '' if parent_module.empty?

        parent_module.split('::').map.with_index do |_, index|
          "#{'  ' * (parent_module.split('::').length - 1 - index)}end"
        end.join("\n") + "\n"
      end
    end
  end
end
