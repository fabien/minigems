require 'rubygems'
require 'rake/gempackagetask'
require File.join(File.dirname(__FILE__), 'lib', 'minigems')

##############################################################################
# Package && release
##############################################################################
RUBY_FORGE_PROJECT  = "merb"
PROJECT_URL         = "http://merbivore.com"
PROJECT_SUMMARY     = "Lighweight drop-in replacement for rubygems."
PROJECT_DESCRIPTION = PROJECT_SUMMARY

GEM_AUTHOR = "Fabien Franzen"
GEM_EMAIL  = "info@atelierfabien.be"

GEM_NAME    = "minigems"
PKG_BUILD   = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
GEM_VERSION = (Gem::MiniGems::VERSION || "0.9.3") + PKG_BUILD

RELEASE_NAME    = "REL #{GEM_VERSION}"

spec = Gem::Specification.new do |s|
  s.rubyforge_project = RUBY_FORGE_PROJECT
  s.name = GEM_NAME
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README", "LICENSE"]
  s.summary = PROJECT_SUMMARY
  s.description = PROJECT_DESCRIPTION
  s.author = GEM_AUTHOR
  s.email = GEM_EMAIL
  s.homepage = PROJECT_URL
  s.bindir = "bin"
  s.executables = %w( minigem )
  s.require_path = "lib"
  s.files = %w(LICENSE README Rakefile) + Dir.glob("{lib,bin,spec}/**/*")
  s.post_install_message = "Run 'minigem' for instructions on how to proceed."
end

def sudo
  ENV['MERB_SUDO'] ||= "sudo"
  sudo = windows? ? "" : ENV['MERB_SUDO']
end

def windows?
  (PLATFORM =~ /win32|cygwin/) rescue nil
end

def install_home
  ENV['GEM_HOME'] ? "-i #{ENV['GEM_HOME']}" : ""
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "removes any generated content"
task :clean do
  FileUtils.rm_rf "clobber/*"
  FileUtils.rm_rf "pkg/*"
end

desc "create a gemspec file"
task :make_spec do
  File.open("#{GEM_NAME}.gemspec", "w") do |file|
    file.puts spec.to_ruby
  end
end

desc "Install the gem"
task :install => [:clean, :package] do
  sh %{#{sudo} #{Gem.ruby} -S gem install #{install_home} pkg/#{GEM_NAME}-#{GEM_VERSION} --no-wrapper --no-update-sources --no-rdoc --no-ri}
end

namespace :jruby do

  desc "Run :package and install the resulting .gem with jruby"
  task :install => :package do
    sh %{#{sudo} jruby -S gem install #{install_home} pkg/#{GEM_NAME}-#{GEM_VERSION}.gem  --no-wrapper --no-rdoc --no-ri}
  end

end
