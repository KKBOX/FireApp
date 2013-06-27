unless defined?(ActionView)
  raise "Rails is not loaded - Temple::Templates::Rails cannot be used"
end

if ::ActionPack::VERSION::MAJOR < 3
  raise "Temple supports only Rails 3.x and greater, your Rails version is #{::ActionPack::VERSION::STRING}"
end

module Temple
  module Templates
    if ::ActionPack::VERSION::MAJOR == 3 && ::ActionPack::VERSION::MINOR < 1
      class Rails < ActionView::TemplateHandler
        include ActionView::TemplateHandlers::Compilable
        extend Mixins::Template

        def compile(template)
          # Overwrite option: No streaming support in Rails < 3.1
          opts = {}.update(self.class.default_options).update(:file => template.identifier, :streaming => false)
          self.class.compile(template.source, opts)
        end

        def self.register_as(*names)
          names.each do |name|
            ActionView::Template.register_template_handler name.to_sym, self
          end
        end
      end
    else
      class Rails
        extend Mixins::Template

        def call(template)
          opts = {}.update(self.class.default_options).update(:file => template.identifier)
          self.class.compile(template.source, opts)
        end

        def supports_streaming?
          self.class.default_options[:streaming]
        end

        def self.register_as(*names)
          names.each do |name|
            ActionView::Template.register_template_handler name.to_sym, new
          end
        end
      end
    end
  end
end
