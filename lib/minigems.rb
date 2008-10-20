module Gem
unless const_defined?(:MiniGems)
  module MiniGems
    
    VERSION = "0.9.8"
    
    # The next line needs to be kept exactly as shown; it's being replaced
    # during minigems installation.
    FULL_RUBYGEMS_METHODS = []

    def self.camel_case(str)
      return str if str !~ /_/ && str =~ /[A-Z]+.*/
      str.split('_').map{|e| e.capitalize}.join
    end
  
  end
end
end

# Enable minigems unless rubygems has already loaded.
unless $LOADED_FEATURES.include?("rubygems.rb")

  $MINIGEMS_SKIPPABLE ||= []

  $LOADED_FEATURES << "rubygems.rb"
  require 'minigems/core'
  require 'rubygems/specification'
  require 'pathname'
  
  unless Gem::MiniGems.const_defined?(:INLINE_REGEXP)
    Gem::MiniGems::INLINE_REGEXP = /^Inline_.*?\.#{Config::CONFIG['DLEXT']}/
  end

  module Kernel
  
    def gem(name, *versions)
      Gem.activate(name, *versions)
    end
  
    if RUBY_VERSION < '1.9' then
  
      alias :gem_original_require :require

      # We replace Ruby's require with our own, which is capable of
      # loading gems on demand.
      #
      # When you call <tt>require 'x'</tt>, this is what happens:
      # * If the file can be loaded from the existing Ruby loadpath, it
      #   is.
      # * Otherwise, installed gems are searched for a file that matches.
      #   If it's found in gem 'y', that gem is activated (added to the
      #   loadpath).
      #
      # The normal <tt>require</tt> functionality of returning false if
      # that file has already been loaded is preserved.
      #
      def require(path) # :nodoc:
        gem_original_require path
      rescue LoadError => load_error
        if File.basename(path).match(Gem::MiniGems::INLINE_REGEXP) && 
          Object.const_defined?(:Inline)
          # RubyInline dynamically created .so/.bundle
          return gem_original_require(File.join(Inline.directory, path))
        elsif path == 'Win32API' && !Gem.win_platform?
          raise load_error
        elsif load_error.message =~ /#{Regexp.escape path}\z/
          if !path.include?('/') && Gem.activate(path)
            return gem_original_require(path)
          elsif $MINIGEMS_SKIPPABLE.include?(path)
            raise load_error
          elsif spec = Gem.searcher.find(path)
            Gem.activate(spec.name, "= #{spec.version}")
            return gem_original_require(path)
          end
        end
        raise load_error
      end
      
    end
  
  end
  
  module Gem
  
    CORE_GEM_METHODS = Gem.methods(false)
  
    class Exception < RuntimeError; end
  
    # Keep track of loaded gems, maps gem name to full_name.
    def self.loaded_gems
      @loaded_gems ||= {}
    end
  
    # Refresh the current 'cached' gems - in this case 
    # just the list of loaded gems.
    def self.refresh
      self.loaded_gems.clear
    end
  
    # See if a given gem is available.
    def self.available?(name, *version_requirements)
      version_requirements = Gem::Requirement.default if version_requirements.empty?
      gem = Gem::Dependency.new(name, version_requirements)
      not find_name(gem).nil?
    end

    # Activates an installed gem matching +gem+.  The gem must satisfy
    # +version_requirements+.
    #
    # Returns true if the gem is activated, false if it is already
    # loaded, or an exception otherwise.
    #
    # Gem#activate adds the library paths in +gem+ to $LOAD_PATH.  Before a Gem
    # is activated its required Gems are activated.  If the version information
    # is omitted, the highest version Gem of the supplied name is loaded.  If a
    # Gem is not found that meets the version requirements or a required Gem is
    # not found, a Gem::LoadError is raised.
    #
    # More information on version requirements can be found in the
    # Gem::Requirement and Gem::Version documentation.
    def self.activate(gem, *version_requirements)
      if match = find_name(gem, *version_requirements)
        activate_gem_from_path(match.first)
      elsif gem.is_a?(String) && 
        (match = find_name(MiniGems.camel_case(gem), *version_requirements))
        activate_gem_from_path(match.first)
      else
        unless gem.respond_to?(:name) && gem.respond_to?(:version_requirements)
          gem = Gem::Dependency.new(gem, version_requirements)
        end
        report_activate_error(gem)
      end
    end
    
    # Helper method to find all current gem paths.
    #
    # Find the most recent gem versions' paths just by looking at the gem's 
    # directory version number. This is faster than parsing gemspec files
    # at the expense of being less complete when it comes to require paths.
    # That's why Gem.activate actually parses gemspecs instead of directories.
    def self.latest_gem_paths
      lookup = {}
      gem_path_sets = self.path.map { |path| [path, Dir["#{path}/gems/*"]] }
      gem_path_sets.each do |root_path, gems|
        unless gems.empty?
          gems.each do |gem_path|
            if matches = File.basename(File.basename(gem_path)).match(/^(.*?)-([\d\.]+)$/)
              name, version_no = matches.captures[0,2]
              version = Gem::Version.new(version_no)
              if !lookup[name] || (lookup[name] && lookup[name][1] < version)
                lookup[name] = [gem_path, version]
              end
            end
          end
        end
      end
      lookup.collect { |name,(gem_path, version)| gem_path }.sort
    end

    # Array of paths to search for Gems.
    def self.path
      @path ||= begin
        paths = [ENV['GEM_PATH'] ? ENV['GEM_PATH'] : default_path]
        paths << APPLE_GEM_HOME if defined?(APPLE_GEM_HOME) && !ENV['GEM_PATH']
        paths
      end
    end
  
    # Default gem load path.
    def self.default_path
      @default_path ||= if defined? RUBY_FRAMEWORK_VERSION then
        File.join File.dirname(RbConfig::CONFIG["sitedir"]), 'Gems', 
          RbConfig::CONFIG["ruby_version"]
      elsif defined?(RUBY_ENGINE) && File.directory?(
        File.join(RbConfig::CONFIG["libdir"], RUBY_ENGINE, 'gems', 
          RbConfig::CONFIG["ruby_version"])
        )
          File.join RbConfig::CONFIG["libdir"], RUBY_ENGINE, 'gems', 
            RbConfig::CONFIG["ruby_version"]
      else
        File.join RbConfig::CONFIG["libdir"], 'ruby', 'gems', 
          RbConfig::CONFIG["ruby_version"]
      end
    end
  
    # Reset the +path+ value. The next time +path+ is requested, 
    # the values will be calculated from scratch.
    def self.clear_paths
      @path = nil
    end
  
    # Catch calls to full rubygems methods - once accessed
    # the current Gem methods are overridden.
    def self.method_missing(m, *args, &blk)
      if Gem::MiniGems::FULL_RUBYGEMS_METHODS.include?(m.to_s)
        load_full_rubygems!
        return send(m, *args, &blk)
      end
      super
    end
  
    # Catch references to full rubygems constants - once accessed
    # the current Gem constants are merged.
    def self.const_missing(const)
      load_full_rubygems!
      if Gem.const_defined?(const)
        Gem.const_get(const)
      else
        super
      end
    end
  
    protected
    
    # Activate a gem by specifying a path to a gemspec.
    def self.activate_gem_from_path(gem_path, gem_spec = nil)
      # Load and initialize the gemspec
      gem_spec ||= Gem::Specification.load(gem_path)
      gem_spec.loaded_from = gem_path
    
      # Raise an exception if the same spec has already been loaded - except for identical matches
      if (already_loaded = self.loaded_gems[gem_spec.name]) && gem_spec.full_name != already_loaded
        raise Gem::Exception, "can't activate #{gem_spec.name}, already activated #{already_loaded}"
      # If it's an identical match, we're done activating
      elsif already_loaded
        return false
      end
          
      # Keep track of loaded gems - by name instead of full specs (memory!)
      self.loaded_gems[gem_spec.name] = gem_spec.full_name
    
      # Load dependent gems first
      gem_spec.runtime_dependencies.each { |dep_gem| activate(dep_gem) }
      
      # bin directory must come before library directories
      gem_spec.require_paths.unshift(gem_spec.bindir) if gem_spec.bindir
    
      # Add gem require paths to $LOAD_PATH
      gem_spec.require_paths.reverse.each do |require_path|
        $LOAD_PATH.unshift File.join(gem_spec.full_gem_path, require_path)
      end
      return true
    end
    
    # Find a file in the source path and activate its gem (best/highest match).
    def self.find_in_source_path(path)
      if ['.rb', '.rbw', '.so', '.bundle', '.dll', '.sl', '.jar'].include?(File.extname(path))
        file_path = path
      else
        file_path = "#{path}.rb"
      end
      matched_paths = self.path.map do |gem_path| 
        [Pathname.new("#{gem_path}/gems"), Dir["#{gem_path}/gems/**/#{file_path}"]]
      end
      versions = matched_paths.inject([]) do |versions, (root_path, paths)|
        paths.each do |matched_path|
          dir_name = Pathname.new(matched_path).relative_path_from(root_path).to_s.split('/').first
          gemspec_path = File.join(File.dirname(root_path), 'specifications', "#{dir_name}.gemspec")
          if File.exists?(gemspec_path)
            # Now check if the file was in a valid require_path
            gem_spec = Gem::Specification.load(gemspec_path)
            gem_spec.loaded_from = gemspec_path
            gem_dir = Pathname.new("#{root_path}/#{dir_name}")
            
            relative_file = Pathname.new(matched_path).relative_path_from(gem_dir).to_s           
            if gem_spec.require_paths.any? { |req| File.join(req, file_path) == relative_file }
              versions << gem_spec
            end
          end
        end
        versions
      end
      versions.max { |a, b| a.version <=> b.version }
    end
    
    # Find a file in the Gem source index - loads up the full rubygems!
    def self.find_in_source_index(path)
      show_notification "Switching from minigems to full rubygems..."
      Gem.searcher.find(path)
    end

    # Find the best (highest) matching gem version.
    def self.find_name(gem, *version_requirements)
      version_requirements = Gem::Requirement.default if version_requirements.empty?
      if gem.respond_to?(:name) && gem.respond_to?(:version_requirements)
        dependency = gem
      else
        dependency = Gem::Dependency.new(gem.to_s, version_requirements)
      end
      
      gemspec_sets = self.path.map { |path| [path, Dir["#{path}/specifications/#{dependency.name}-*.gemspec"]] }
      versions = gemspec_sets.inject([]) do |versions, (root_path, gems)|
        unless gems.empty?
          gems.each do |gemspec_path|
            if (version_no = gemspec_path[/-([\d\.]+)\.gemspec$/, 1]) &&
              dependency.version_requirements.satisfied_by?(version = Gem::Version.new(version_no))
              versions << [gemspec_path, version]
            end
          end
        end
        versions
      end
      versions.max { |a, b| a.last <=> b.last }
    end
  
    # Report a load error during activation.
    def self.report_activate_error(gem)
      error = Gem::LoadError.new("Could not find RubyGem #{gem.name} (#{gem.version_requirements})\n")
      error.name = gem.name
      error.version_requirement = gem.version_requirements
      raise error
    end
  
    # Load the full rubygems suite, at which point all minigems logic
    # is being overridden, so all regular methods and classes are available.
    def self.load_full_rubygems!
      show_notification 'Loaded full RubyGems instead of MiniGems'
      if !caller.first.to_s.match(/`const_missing'$/) && (require_entry = get_require_caller(caller))
        show_notification "A gem was possibly implicitly loaded from #{require_entry}"
      end
      # Clear out any minigems methods
      class << self
        (MINIGEMS_METHODS - CORE_GEM_METHODS).each do |method_name|
          undef_method method_name
        end
      end
      # Fix some constants from throwing already initialized warnings
      Gem.send(:remove_const, :RubyGemsPackageVersion)
      Gem.send(:remove_const, :WIN_PATTERNS)
      # Re-alias the 'require' method back to its original.
      ::Kernel.module_eval { alias_method :require, :gem_original_require }
      require $LOADED_FEATURES.delete("rubygems.rb")
    end
    
    def self.get_require_caller(callstack)
      require_entry = callstack.find { |c| c =~ /`require'$/ }
      if require_entry && (idx = callstack.index(require_entry)) && (entry = callstack[idx + 1])
        entry
      end
    end
    
    def self.show_notification(msg)
      puts "\033[1;31m#{msg}\033[0m"
    end
  
    # Record all minigems methods - except the minigems? predicate method.
    MINIGEMS_METHODS = Gem.methods(false) - ["minigems?"]
    
  end
  
end