# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "asset_pipeline_i18n/version"

Gem::Specification.new do |s|
  s.name        = "asset_pipeline_i18n"
  s.version     = AssetPipelineI18n::VERSION
  s.authors     = ["Nicola Piccinini", "Corin Langosch"]
  s.email       = ["nicola.piccinini@simplificator.com", "info@corinlangosch.com"]
  s.homepage    = "https://github.com/simplificator/asset_pipeline_i18n"
  s.summary     = %q{Localized precompiled assets for Rails}
  s.description = %q{Localized precompiled assets for Rails}

  s.rubyforge_project = "asset_pipeline_i18n"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_runtime_dependency "rails", "~> 4.0.1"
end
