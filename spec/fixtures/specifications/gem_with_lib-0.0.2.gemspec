Gem::Specification.new do |s|
  s.name = %q{gem_with_lib}
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Your Name"]
  s.date = %q{2008-08-19}
  s.description = %q{A gem that provides...}
  s.email = %q{Your Email}
  s.extra_rdoc_files = ["README", "LICENSE", "TODO"]
  s.files = ["LICENSE", "README", "Rakefile", "TODO", "lib/gem_with_lib.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://example.com}
  s.executables = %w( gem_with_lib )
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{A gem that provides...}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
    else
    end
  else
  end
end
