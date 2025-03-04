require_relative "lib/active_record_auditable/version"

Gem::Specification.new do |spec|
  spec.name        = "active_record_auditable"
  spec.version     = ActiveRecordAuditable::VERSION
  spec.authors     = ["kaspernj"]
  spec.email       = ["kasper@diestoeckels.de"]
  spec.homepage    = "https://github.com/kaspernj/active_record_auditable"
  spec.summary     = "Audits for your records."
  spec.description = "Audits for your records."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/kaspernj/active_record_auditable"
  spec.metadata["changelog_uri"] = "https://github.com/kaspernj/active_record_auditable/blob/master/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0.0"
  spec.add_dependency "service_pattern", ">= 1.0.10"
end
