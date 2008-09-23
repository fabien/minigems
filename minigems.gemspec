Gem::Specification.new do |s|
  s.name = %q{minigems}
  s.version = "0.9.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Fabien Franzen"]
  s.date = %q{2008-09-20}
  s.default_executable = %q{minigem}
  s.description = %q{Lighweight drop-in replacement for rubygems.}
  s.email = %q{info@atelierfabien.be}
  s.executables = ["minigem"]
  s.extra_rdoc_files = ["README", "LICENSE"]
  s.files = ["LICENSE", "README", "Rakefile", "lib/minigems", "lib/minigems/executable_wrapper", "lib/minigems/script_helper.rb", "lib/minigems.rb", "bin/minigem", "spec/fixtures", "spec/fixtures/cache", "spec/fixtures/cache/gem_with_lib-0.0.1.gem", "spec/fixtures/cache/gem_with_lib-0.0.2.gem", "spec/fixtures/gems", "spec/fixtures/gems/gem_with_lib-0.0.1", "spec/fixtures/gems/gem_with_lib-0.0.1/lib", "spec/fixtures/gems/gem_with_lib-0.0.1/lib/gem_with_lib.rb", "spec/fixtures/gems/gem_with_lib-0.0.1/LICENSE", "spec/fixtures/gems/gem_with_lib-0.0.1/Rakefile", "spec/fixtures/gems/gem_with_lib-0.0.1/README", "spec/fixtures/gems/gem_with_lib-0.0.1/TODO", "spec/fixtures/gems/gem_with_lib-0.0.2", "spec/fixtures/gems/gem_with_lib-0.0.2/bin", "spec/fixtures/gems/gem_with_lib-0.0.2/bin/gem_with_lib", "spec/fixtures/gems/gem_with_lib-0.0.2/lib", "spec/fixtures/gems/gem_with_lib-0.0.2/lib/gem_with_lib.rb", "spec/fixtures/gems/gem_with_lib-0.0.2/LICENSE", "spec/fixtures/gems/gem_with_lib-0.0.2/Rakefile", "spec/fixtures/gems/gem_with_lib-0.0.2/README", "spec/fixtures/gems/gem_with_lib-0.0.2/TODO", "spec/fixtures/specifications", "spec/fixtures/specifications/gem_with_lib-0.0.1.gemspec", "spec/fixtures/specifications/gem_with_lib-0.0.2.gemspec", "spec/minigems_spec.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://merbivore.com}
  s.post_install_message = %q{Run 'minigem' for instructions on how to proceed.}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{merb}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Lighweight drop-in replacement for rubygems.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
    else
    end
  else
  end
end
