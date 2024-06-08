require 'rails/generators'
require 'rails/generators/named_base'

module ApacheAge
  class NodeGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('templates', __dir__)
    argument :attributes, type: :array, default: [], banner: "field:type field:type"

    def perform_task
      behavior == :invoke ? create_node_file : destroy_node_file
    end

    private

    def create_node_file
      template "node.rb.tt", File.join(destination_root, "app/nodes", class_path, "#{file_name}.rb")
      add_type_config
    end

    def destroy_node_file
      file_path = File.join(destination_root, "app/nodes", class_path, "#{file_name}.rb")
      File.delete(file_path) if File.exist?(file_path)
      remove_type_config
    end

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

    def add_type_config
      return unless File.exist?(types_config_file)

      new_type_info = new_type_content

      types_content = File.read(types_config_file)
      types_content.sub!(/^end\s*$/, "#{new_type_info}\nend")
      File.open(types_config_file, 'w') { |file| file.write(types_content) }
      puts "      modified: config/initializers/types.rb"
    end

    def remove_type_config
      return unless File.exist?(types_config_file)

      type_to_remove = new_type_content

      types_content = File.read(types_config_file)
      types_content.gsub!(type_to_remove, '')
      File.open(types_config_file, 'w') { |file| file.write(types_content) }
    end

    def types_config_file = File.join(Rails.root, 'config', 'initializers', 'types.rb')

    def new_type_content
      file_path = File.join("app/nodes", class_path, file_name)
      namespace = class_path.map(&:capitalize).join('::')
      class_name = file_name.split('_').map(&:capitalize).join
      node_name = [namespace, class_name].compact.join('::')
      type_name = [class_path.join('_'), file_name].compact.join('_')

      type_to_remove =
      <<~RUBY
        require_dependency '#{file_path}'
        ActiveModel::Type.register(
          :#{type_name}, ApacheAge::Types::AgeTypeGenerator.create_type_for(#{node_name})
        )
      RUBY
    end
  end
end
