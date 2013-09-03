# https://github.com/rails/rails/blob/v3.2.14/actionpack/lib/sprockets/assets.rake
namespace :assets do
  namespace :precompile do
    def internal_precompile(digest = nil)
      # we have to reinvoke the rask task as we need a clean sprockets env
      # this sucks, but well, cannot be changed due to design flaws in rails/ sprockets...
      i18n_assets_grouped_by_locale.keys.each do |locale|
        ENV['DIGEST'] = digest.nil? ? "true" : "false"
        ENV['LOCALE'] = locale
        ruby_rake_task "assets:precompile:localized"
      end

      # merge manifests on second (last) precompile run
      merge_precompiled_assets if digest == false
    end

    def internal_precompile_i18n(assets, locale, digest = nil)
      puts "Precompiling assets with locale #{locale}..."
      I18n.locale = locale

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

      env = Rails.application.assets
      target = File.join(tmp_path, locale)
      Sprockets::StaticCompiler.new(env, target, assets, :manifest_path => config.assets.manifest, :digest => config.assets.digest, :manifest => digest.nil?).compile
    end

    def i18n_assets_grouped_by_locale
      Rails.application.config.assets.localized_precompile.map{ |name| {:name => name, :locale => name.match(/-([a-z]+)\./)[1]} }.group_by{ |v| v[:locale] }.each_value{ |g| g.map!{ |i| i[:name] } }
    end

    def precompile_assets(locale, digest)
      assets = i18n_assets_grouped_by_locale[locale]
      assets.concat(Rails.application.config.assets.precompile) if I18n.default_locale.to_s == locale
      internal_precompile_i18n(assets, locale, digest)
    end

    def manifest_filename
      Rails.application.config.assets.manifest || "manifest.yml"
    end

    def real_path
      File.join(Rails.public_path, Rails.application.config.assets.prefix)
    end

    def tmp_path
      File.join(real_path, "tmp")
    end

    def merge_precompiled_assets
      puts "Building manifest..."
      manifest = {}

      i18n_assets_grouped_by_locale.keys.each do |locale|
        root_path = File.join(tmp_path, locale)
        Dir[File.join(root_path, *(["/**"]*10))].each do |src_path|
          dst_path = File.join(real_path, src_path[(root_path.length + 1)..-1])

          name = File.basename(src_path)
          folder = File.dirname(src_path)
          if name == manifest_filename
            File.open(src_path, "rb") do |f|
              manifest.merge!(YAML::load(f))
            end
            next
          end

          if File.directory?(src_path)
            FileUtils.mkdir(dst_path) unless File.exists?(dst_path)
          else
            FileUtils.cp(src_path, dst_path)
          end
        end
      end

      File.open(File.join(real_path, manifest_filename), "wb") do |f|
        YAML.dump(manifest, f)
      end

      FileUtils.rm_r(tmp_path)
    end

    task :localized => ["assets:environment", "tmp:cache:clear"] do
      precompile_assets(ENV['LOCALE'], (ENV['DIGEST'] == "true") ? nil : false)
    end
  end
end
