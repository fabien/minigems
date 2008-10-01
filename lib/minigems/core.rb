require 'rubygems/rubygems_version'
require 'rubygems/defaults'

module Gem
  class LoadError < ::LoadError
    attr_accessor :name, :version_requirement
  end
end

module Gem

  ConfigMap = {} unless defined?(ConfigMap)
  require 'rbconfig'
  RbConfig = Config unless defined? ::RbConfig

  ConfigMap.merge!(
    :BASERUBY => RbConfig::CONFIG["BASERUBY"],
    :EXEEXT => RbConfig::CONFIG["EXEEXT"],
    :RUBY_INSTALL_NAME => RbConfig::CONFIG["RUBY_INSTALL_NAME"],
    :RUBY_SO_NAME => RbConfig::CONFIG["RUBY_SO_NAME"],
    :arch => RbConfig::CONFIG["arch"],
    :bindir => RbConfig::CONFIG["bindir"],
    :datadir => RbConfig::CONFIG["datadir"],
    :libdir => RbConfig::CONFIG["libdir"],
    :ruby_install_name => RbConfig::CONFIG["ruby_install_name"],
    :ruby_version => RbConfig::CONFIG["ruby_version"],
    :sitedir => RbConfig::CONFIG["sitedir"],
    :sitelibdir => RbConfig::CONFIG["sitelibdir"],
    :vendordir => RbConfig::CONFIG["vendordir"] ,
    :vendorlibdir => RbConfig::CONFIG["vendorlibdir"]
  )

  DIRECTORIES = %w[cache doc gems specifications] unless defined?(DIRECTORIES)

  RubyGemsPackageVersion = RubyGemsVersion unless defined?(RubyGemsPackageVersion)
  
  ##
  # An Array of Regexps that match windows ruby platforms.
  
  unless defined?(WIN_PATTERNS)
    WIN_PATTERNS = [/bccwin/i, /cygwin/i, /djgpp/i, /mingw/i, /mswin/i, /wince/i]
  end
  
  @@win_platform = nil
  
  @platforms = []
  @ruby = nil
  
  ##
  # Whether minigems is being used or full rubygems has taken over.
  
  def self.minigems?
    not const_defined?(:SourceIndex)
  end
  
  ##
  # The path to the running Ruby interpreter.

  def self.ruby
    if @ruby.nil? then
      @ruby = File.join(ConfigMap[:bindir], ConfigMap[:ruby_install_name])
      @ruby << ConfigMap[:EXEEXT]
      # escape string in case path to ruby executable contain spaces.
      @ruby.sub!(/.*\s.*/m, '"\&"')
    end
    @ruby
  end

  ##
  # A Gem::Version for the currently running ruby.

  def self.ruby_version
    return @ruby_version if defined? @ruby_version
    version = RUBY_VERSION.dup
    version << ".#{RUBY_PATCHLEVEL}" if defined? RUBY_PATCHLEVEL
    @ruby_version = Gem::Version.new version
  end
  
  ##
  # Is this a windows platform?

  def self.win_platform?
    if @@win_platform.nil? then
      @@win_platform = !!WIN_PATTERNS.find { |r| RUBY_PLATFORM =~ r }
    end
    @@win_platform
  end
  
  ##
  # The path where gem executables are to be installed.

  def self.bindir(install_dir=Gem.dir)
    return File.join(install_dir, 'bin') unless
      install_dir.to_s == Gem.default_dir
    Gem.default_bindir
  end
  
  ##
  # The path where gems are to be installed.

  def self.dir
    @gem_home ||= nil
    set_home(ENV['GEM_HOME'] || default_dir) unless @gem_home
    @gem_home
  end
  
  ##
  # Quietly ensure the named Gem directory contains all the proper
  # subdirectories.  If we can't create a directory due to a permission
  # problem, then we will silently continue.

  def self.ensure_gem_subdirectories(gemdir)
    require 'fileutils'

    Gem::DIRECTORIES.each do |filename|
      fn = File.join gemdir, filename
      FileUtils.mkdir_p fn rescue nil unless File.exist? fn
    end
  end
  
  ##
  # Finds the user's home directory.
  #--
  # Some comments from the ruby-talk list regarding finding the home
  # directory:
  #
  #   I have HOME, USERPROFILE and HOMEDRIVE + HOMEPATH. Ruby seems
  #   to be depending on HOME in those code samples. I propose that
  #   it should fallback to USERPROFILE and HOMEDRIVE + HOMEPATH (at
  #   least on Win32).

  def self.find_home
    ['HOME', 'USERPROFILE'].each do |homekey|
      return ENV[homekey] if ENV[homekey]
    end

    if ENV['HOMEDRIVE'] && ENV['HOMEPATH'] then
      return "#{ENV['HOMEDRIVE']}#{ENV['HOMEPATH']}"
    end

    begin
      File.expand_path("~")
    rescue
      File::ALT_SEPARATOR ? "C:/" : "/"
    end
  end

  private_class_method :find_home
  
  ##
  # The index to insert activated gem paths into the $LOAD_PATH.

  def self.load_path_insert_index
    $LOAD_PATH.index ConfigMap[:sitelibdir]
  end
  
  ##
  # The file name and line number of the caller of the caller of this method.

  def self.location_of_caller
    file, lineno = caller[1].split(':')
    lineno = lineno.to_i
    [file, lineno]
  end

  private_class_method :location_of_caller
  
  ##
  # The version of the Marshal format for your Ruby.

  def self.marshal_version
    "#{Marshal::MAJOR_VERSION}.#{Marshal::MINOR_VERSION}"
  end
  
  ##
  # Array of paths to search for Gems.

  def self.path
    @gem_path ||= nil

    unless @gem_path then
      paths = if ENV['GEM_PATH'] then
                [ENV['GEM_PATH']]
              else
                [default_path]
              end

      if defined?(APPLE_GEM_HOME) and not ENV['GEM_PATH'] then
        paths << APPLE_GEM_HOME
      end

      set_paths paths.compact.join(File::PATH_SEPARATOR)
    end

    @gem_path
  end

  ##
  # Set array of platforms this RubyGems supports (primarily for testing).

  def self.platforms=(platforms)
    @platforms = platforms
  end

  ##
  # Array of platforms this RubyGems supports.

  def self.platforms
    @platforms ||= []
    if @platforms.empty?
      @platforms = [Gem::Platform::RUBY, Gem::Platform.local]
    end
    @platforms
  end
  
  ##
  # The directory prefix this RubyGems was installed at.

  def self.prefix
    prefix = File.dirname File.expand_path(File.join(__FILE__, '..'))

    if File.dirname(prefix) == File.expand_path(ConfigMap[:sitelibdir]) or
       File.dirname(prefix) == File.expand_path(ConfigMap[:libdir]) or
       'lib' != File.basename(prefix) then
      nil
    else
      File.dirname prefix
    end
  end
  
  ##
  # Set the Gem home directory (as reported by Gem.dir).

  def self.set_home(home)
    home = home.gsub(File::ALT_SEPARATOR, File::SEPARATOR) if File::ALT_SEPARATOR
    @gem_home = home
    ensure_gem_subdirectories(@gem_home)
  end

  private_class_method :set_home

  ##
  # Set the Gem search path (as reported by Gem.path).

  def self.set_paths(gpaths)
    if gpaths
      @gem_path = gpaths.split(File::PATH_SEPARATOR)

      if File::ALT_SEPARATOR then
        @gem_path.map! do |path|
          path.gsub File::ALT_SEPARATOR, File::SEPARATOR
        end
      end

      @gem_path << Gem.dir
    else
      # TODO: should this be Gem.default_path instead?
      @gem_path = [Gem.dir]
    end

    @gem_path.uniq!
    @gem_path.each do |gp| ensure_gem_subdirectories(gp) end
  end

  private_class_method :set_paths
  
  ##
  # Glob pattern for require-able path suffixes.

  def self.suffix_pattern
    @suffix_pattern ||= "{#{suffixes.join(',')}}"
  end

  ##
  # Suffixes for require-able paths.

  def self.suffixes
    ['', '.rb', '.rbw', '.so', '.bundle', '.dll', '.sl', '.jar']
  end
  
  ##
  # Use the +home+ and +paths+ values for Gem.dir and Gem.path.  Used mainly
  # by the unit tests to provide environment isolation.

  def self.use_paths(home, paths=[])
    clear_paths
    set_home(home) if home
    set_paths(paths.join(File::PATH_SEPARATOR)) if paths
  end

  ##
  # The home directory for the user.

  def self.user_home
    @user_home ||= find_home
  end

end

module Config
  # :stopdoc:
  class << self
    # Return the path to the data directory associated with the named
    # package.  If the package is loaded as a gem, return the gem
    # specific data directory.  Otherwise return a path to the share
    # area as define by "#{ConfigMap[:datadir]}/#{package_name}".
    def datadir(package_name)
      Gem.datadir(package_name) ||
        File.join(Gem::ConfigMap[:datadir], package_name)
    end
  end
  # :startdoc:
end

require 'rubygems/exceptions'
require 'rubygems/version'
require 'rubygems/requirement'
require 'rubygems/dependency'

begin
  require 'rubygems/defaults/operating_system'
rescue LoadError
end

if defined?(RUBY_ENGINE) then
  begin
    require "rubygems/defaults/#{RUBY_ENGINE}"
  rescue LoadError
  end
end