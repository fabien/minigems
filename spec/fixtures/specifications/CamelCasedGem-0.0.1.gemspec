# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{CamelCasedGem}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Your Name"]
  s.date = %q{2008-09-23}
  s.description = %q{A gem that provides...}
  s.email = %q{Your Email}
  s.extra_rdoc_files = ["README", "LICENSE", "TODO"]
  s.files = ["LICENSE", "README", "Rakefile", "TODO", "lib/camel_cased_gem.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://example.com}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.2.0.1874}
  s.summary = %q{A gem that provides...}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
