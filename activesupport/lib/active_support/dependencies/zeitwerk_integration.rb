module ActiveSupport
  module Dependencies
    module ZeitwerkIntegration
      module Decorations
        def clear
          Dependencies.unload_interlock do
            Rails.autoloader.reload
          end
        end

        def constantize(cpath)
          Inflector.constantize(cpath)
        end

        def safe_constantize(cpath)
          Inflector.safe_constantize(cpath)
        end

        def autoloaded_constants
          Rails.autoloader.loaded.to_a
        end

        def autoloaded?(object)
          cpath = object.is_a?(Module) ? object.name : object.to_s
          Rails.autoloader.loaded?(cpath)
        end
      end

      class << self
        def take_over
          setup_rails_autoloader
          setup_once_autoloader
          freeze_paths
          decorate
        end

        private

          def setup_rails_autoloader
            (Dependencies.autoload_paths - Dependencies.autoload_once_paths).each do |path|
              Rails.autoloader.push_dir(path) if File.directory?(path)
            end
            Rails.autoloader.setup
          end

          def setup_once_autoloader
            once_autoloader = Zeitwerk::Loader.new
            Dependencies.autoload_once_paths.each do |path|
              once_autoloader.push_dir(path) if File.directory?(path)
            end
            once_autoloader.setup
          end

          def freeze_paths
            Dependencies.autoload_paths.freeze
            Dependencies.autoload_once_paths.freeze
          end

          def decorate
            Dependencies.singleton_class.prepend(Decorations)
            Object.class_eval { alias_method :require_dependency, :require }
          end
      end
    end
  end
end
