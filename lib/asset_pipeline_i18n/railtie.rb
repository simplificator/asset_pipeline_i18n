require 'rails'
require 'sprockets/rails/task'

module AssetPipelineI18n
  class Railtie < Rails::Railtie
    initializer "asset_pipeline_i18n.initialization" do
      Sprockets::Rails::Task.new(Rails.application) do |t|
        #
        # predefined methods we need to customize
        #

        def t.assets
          Rails.configuration.localized_assets.map{ |name| name % {:locale => I18n.locale} }
        end

        def t.define
          # This implementation gets called in addition to the original implementation
          # when executing the rake task
          namespace :assets do
            desc "Compile all the assets named in config.assets.precompile"
            task :precompile => :environment do
              I18n.available_locales.each do |locale|
                Rails.logger.info "Compiling assets for locale #{locale}..."
                I18n.locale = locale
                with_logger do
                  clean_cache
                  manifest.compile(assets)
                end
              end

              I18n.locale = I18n.default_locale
              Rails.logger.info "Reset locale to default of #{I18n.locale}..."
            end
          end
        end

        #
        # new methods for better code structure on our side
        #

        def t.clean_cache
          env = manifest.environment
          def env.expire_index!
            @assets.clear
          end
          manifest.environment.send(:expire_index!)
          rm_rf(cache_path)
        end
      end
    end
  end
end
