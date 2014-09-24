require_relative '../../../ext/rails/generators/generated_attribute'

module ActiveNode
  class ModelGenerator < Rails::Generators::NamedBase
    source_root File.expand_path('../templates', __FILE__)
    check_class_collision

    class_option :timestamps,
      type: :boolean,
      default: true

    hook_for :test_framework,
      as: :model,
      aliases: '-t'

    argument :attributes,
      type: :array,
      default: [],
      banner: 'attribute[:type] attribute[:type]'

    def create_model_file
      template 'model.rb.erb', File.join('app/models', class_path, "#{file_name}.rb")
    end
  end
end
