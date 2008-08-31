require 'rubygems/gem_runner'
require 'rubygems/exceptions'
require 'rubygems/commands/install_command'
require 'rubygems/commands/update_command'
require 'fileutils'

module Gem

  class GemRunner
    def run_command(command_name, args)
      args.unshift command_name.to_s
      do_configuration(args)
      cmd_manager = @command_manager_class.instance
      config_args = Gem.configuration[command_name.to_s]
      config_args = case config_args
                    when String
                      config_args.split ' '
                    else
                      Array(config_args)
                    end
      Command.add_specific_extra_args(command_name, config_args)
      cmd_manager.run(Gem.configuration.args)
    rescue Gem::SystemExitException
      cmd_manager.cmd
    ensure
      cmd_manager.cmd
    end
  end
  
  class Command
    def get_all_referenced_gem_specs
      get_all_gem_names.map { |name| Gem.source_index.search(name).last }.compact
    end
  end
  
  class CommandManager
    attr_accessor :cmd
    alias :original_find_command :find_command
    def find_command(cmd_name)
      self.cmd = original_find_command(cmd_name)
      self.cmd
    end
  end

  module MiniGems
    module ScriptHelper
  
      def minigems_path
        @minigems_path ||= begin
          if (gem_spec = Gem.source_index.search('minigems').last)
            gem_spec.full_gem_path
          else
            raise "Minigems gem not found!"
          end
        end
      end
  
      def adapt_executables_for(gemspec)
        gemspec.executables.each do |executable|
          next if executable == 'minigem' # better not modify minigem itself
          if File.exists?(wrapper_path = File.join(Gem.bindir, executable))
            wrapper_code = interpolate_wrapper(gemspec.name, executable)
            if File.open(wrapper_path, 'w') { |f| f.write(wrapper_code) }
              puts "Adapted #{wrapper_path} to use minigems instead of rubygems."
            else
              puts "Failed to adapt #{wrapper_path} - maybe you need sudo permissions?"
            end
          end
        end
      end

      def ensure_in_load_path!(force = false)
        install_path = File.join(Gem::ConfigMap[:sitelibdir], 'minigems.rb')
        if force || !File.exists?(install_path)
          if File.exists?(source_path = File.join(minigems_path, 'lib', 'minigems.rb'))
            begin
              FileUtils.copy_file(source_path, install_path)
              puts "Installed minigems at #{install_path}"
            rescue Errno::EACCES
              puts "Could not install minigems at #{install_path} (try sudo)"
            end
          end
        end
      end
      
      def interpolate_wrapper(gem_name, executable_name)
        @template_code ||= File.read(File.join(minigems_path, 'lib', 'minigems', 'executable_wrapper'))
        vars = { 'GEM_NAME' => gem_name, 'EXECUTABLE_NAME' => executable_name }
        vars['SHEBANG'] = "#!/usr/bin/env " + Gem::ConfigMap[:ruby_install_name]
        vars.inject(@template_code) { |str,(k,v)| str.gsub(k,v) }
      end
  
    end
  end
  
end