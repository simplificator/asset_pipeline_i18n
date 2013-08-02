# actionpack-3.2.3/lib/sprockets/assets.rake
require "fileutils"
namespace :i18n do
  namespace :assets do
    def ruby_rake_task(task, fork = true)
      env    = ENV['RAILS_ENV'] || 'production'
      groups = ENV['RAILS_GROUPS'] || 'assets'
      args   = [$0, task,"RAILS_ENV=#{env}","RAILS_GROUPS=#{groups}"]
      args << "--trace" if Rake.application.options.trace
      if $0 =~ /rake\.bat\Z/i
        Kernel.exec $0, *args
      else
        fork ? ruby(*args) : Kernel.exec(FileUtils::RUBY, *args)
      end
    end

    # We are currently running with no explicit bundler group
    # and/or no explicit environment - we have to reinvoke rake to
    # execute this task.
    def invoke_or_reboot_rake_task(task)
      if ENV['RAILS_GROUPS'].to_s.empty? || ENV['RAILS_ENV'].to_s.empty?
        ruby_rake_task task
      else
        Rake::Task[task].invoke
      end
    end

    desc "Compile all the localized assets named in config.assets.localized_precompile"
    task :precompile do
      invoke_or_reboot_rake_task "i18n:assets:precompile:all"
    end

    namespace :precompile do
      def internal_localized_precompile(digest = nil)
        unless Rails.application.config.assets.enabled
          warn "Cannot precompile assets if sprockets is disabled. Please set config.assets.enabled to true"
          exit
        end

        # Ensure that action view is loaded and the appropriate
        # sprockets hooks get executed
        _ = ActionView::Base

        config = Rails.application.config
        config.assets.compile = true
        config.assets.digest  = digest unless digest.nil?
        config.assets.digests = {}

        # changes for i18n
        env      = Rails.application.assets
        target   = File.join(Rails.public_path, config.assets.prefix)

        asset = ENV['LOCALIZED_ASSET']
        I18n.locale = manifest_locale(asset)

        compiler = Sprockets::StaticCompiler.new(env,
                                                 target,
                                                 [asset], # i18n change
                                                 :manifest_path => manifest_path(asset), # i18n change
                                                 :digest => config.assets.digest,
                                                 :manifest => digest.nil?)
        compiler.compile
      end

      def manifest_locale(localized_asset)
        localized_asset.match(/-([^.]+)/)[1]
      end

      def manifest_path(localized_asset)
        (Rails.configuration.assets.manifest ? Rails.configuration.assets.manifest : File.join(Rails.public_path, Rails.configuration.assets.prefix)) + "/" + localized_asset.match(/([^.]+)/)[1]
      end

      # i18n
      def merge_manifests
        config = Rails.application.config
        target = File.join(Rails.public_path, config.assets.prefix)

        manifest_file = config.assets.manifest ? "#{config.assets.manifest}/manifest.yml" : "#{target}/manifest.yml"
        unless File.exist?(manifest_file)
          warn "Manifest file is missing. Please run standard assets:precompile before i18n:assets:precompile"
          exit 1
        end
        File.open(manifest_file) do |f|
          manifest = YAML::load(f)
        end

        if config.assets.localized_precompile
          config.assets.localized_precompile.each do |asset|
            File.open(manifest_path(asset)) do |f|
              localized_manifest = YAML::load(f)
              manifest.merge!(localized_manifest)
            end
          end
        end

        File.open(manifest_file, 'wb') do |f|
          YAML.dump(manifest, f)
        end
      end

      # i18n
      task :merge_manifests do
        merge_manifests
      end

      task :all do
        ruby_rake_task "i18n:assets:precompile:localized"
        merge_manifests
      end

      task :primary => ["assets:environment", "tmp:cache:clear"] do
        internal_precompile
      end

      task :nondigest => ["assets:environment", "tmp:cache:clear"] do
        internal_precompile(false)
      end

      # i18n
      task :localized do
        config = Rails.application.config
        if config.assets.localized_precompile
          config.assets.localized_precompile.each do |asset|
            puts "Invoking assets precompile task for localized asset #{asset}..."
            ENV['LOCALIZED_ASSET'] = asset
            ruby_rake_task "i18n:assets:precompile:localized_asset"
          end
        end
      end

      # i18n
      task :localized_asset do
        Rake::Task["i18n:assets:precompile:localized_primary"].invoke
        ruby_rake_task("i18n:assets:precompile:localized_nondigest", false) if Rails.application.config.assets.digest
      end

      # i18n
      task :localized_primary => ["assets:environment", "tmp:cache:clear"] do
        internal_localized_precompile
      end

      # i18n
      task :localized_nondigest => ["assets:environment", "tmp:cache:clear"] do
        internal_localized_precompile(false)
      end
    end
  end
end
