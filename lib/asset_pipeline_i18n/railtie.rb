require 'asset_pipeline_i18n'
require 'rails'
module AssetPipelineI18n
  class Railtie < Rails::Railtie
    railtie_name :asset_pipeline_i18n

    rake_tasks do
      load "tasks/assets_i18n.rake"
    end
  end
end
