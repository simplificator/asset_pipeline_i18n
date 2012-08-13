Gem::Specification.new do |s|
  s.name = "asset_pipeline_i18n"
  s.summary = "Localized precompiled assets for rails"
  s.authors = ['Nicola Piccinini']
  s.email = 'nicola.piccinini@simplificator.com'
  s.description = "Provide some additional rake task to precompile assets for any available locale"
  s.files = Dir["{app,lib,config}/**/*"] + ["MIT-LICENSE", "Rakefile", "Gemfile", "README.rdoc"]
  s.version = "3.2.8"
  s.homepage = 'https://github.com/simplificator/asset_pipeline_i18n'

  s.add_dependency "actionpack", "~> 3.2.8"  
end
