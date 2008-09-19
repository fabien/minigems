require File.join(File.dirname(__FILE__), '..', 'lib', 'minigems')

# We can't use the spec runner, as that will already load or full gems!
gem "rspec"
require "spec"

describe Gem::MiniGems do
  
  before do
    # Setup rubygems from our spec fixtures directory
    Gem.refresh
    @gem_dir = File.join(File.dirname(__FILE__), "fixtures")
    Gem.path.replace([@gem_dir])
  end
  
  after do
    # Remove fixture load paths from $LOAD_PATH for specs
    $LOAD_PATH.reject! { |path| path.index(@gem_dir) == 0 }
    $LOADED_FEATURES.delete("gem_with_lib.rb")
    # Make sure any loaded classes are removed
    Object.send(:remove_const, "GemWithLib") if Object.const_defined?("GemWithLib")
    Gem.should be_minigems
  end
  
  it "has a replaceable Gem.path" do
    Gem.path.replace(["awesome"])
    Gem.path.should == ["awesome"]
  end
    
  it "loads gems through the Kernel#require method" do
    require("gem_with_lib").should be_true
    lambda { GemWithLib::Awesome }.should_not raise_error(NameError)
    GemWithLib::VERSION.should == "0.0.2"
  end
  
  it "lets you check for gem availability" do
    Gem.available?("unknown_gem").should be_false
    Gem.available?("gem_with_lib").should be_true
    Gem.available?("gem_with_lib", "0.0.1").should be_true
    Gem.available?("gem_with_lib", "0.0.2").should be_true
    Gem.available?("gem_with_lib", ">0.0.1").should be_true
    Gem.available?("gem_with_lib", ">0.0.2").should be_false
  end
  
  it "should raise Gem::LoadError if no matching gem was found" do
    lambda { gem("unknown_gem") }.should raise_error(Gem::LoadError)
  end
  
  it "uses 'gem' to setup additional load path entries" do
    gem_lib_path = File.join(@gem_dir, "gems", "gem_with_lib-0.0.2", "lib")
    gem_bin_path = File.join(@gem_dir, "gems", "gem_with_lib-0.0.2", "bin")
    $LOAD_PATH.should_not include(gem_lib_path)
    gem("gem_with_lib").should be_true
    $LOAD_PATH.first.should == gem_bin_path
    $LOAD_PATH.should include(gem_lib_path)
    $LOAD_PATH.select { |path| path == gem_lib_path }.length.should == 1
    lambda { GemWithLib::Awesome }.should raise_error(NameError)
  end
  
  it "uses 'gem' to setup additional load path entries (for a specific gem version)" do
    gem_lib_path = File.join(@gem_dir, "gems", "gem_with_lib-0.0.1", "lib")
    gem_bin_path = File.join(@gem_dir, "gems", "gem_with_lib-0.0.1", "bin")
    $LOAD_PATH.should_not include(gem_lib_path)
    gem("gem_with_lib", "0.0.1").should be_true
    $LOAD_PATH.first.should == gem_bin_path
    $LOAD_PATH.should include(gem_lib_path)
  end
  
  it "uses 'gem' to setup additional load path entries (for a gem version requirement)" do
    gem_lib_path = File.join(@gem_dir, "gems", "gem_with_lib-0.0.2", "lib")
    gem_bin_path = File.join(@gem_dir, "gems", "gem_with_lib-0.0.2", "bin")
    $LOAD_PATH.should_not include(gem_lib_path)
    gem("gem_with_lib", ">0.0.1").should be_true
    $LOAD_PATH.first.should == gem_bin_path
    $LOAD_PATH.should include(gem_lib_path)
  end
  
  it "correctly requires a file from the load path" do
    gem("gem_with_lib").should be_true
    require("gem_with_lib").should be_true
    lambda { GemWithLib::Awesome }.should_not raise_error(NameError)
    GemWithLib::VERSION.should == "0.0.2"
  end
  
  it "returns all the latest gem versions' paths" do
    Gem.latest_gem_paths.should == [File.join(@gem_dir, "gems", "gem_with_lib-0.0.2")]
  end
  
  # The following specs can only be run in isolation as they load up the
  # full rubygems library - which cannot really be undone!
  # Comment out the specs above, including before/after setup.
  
  # it "should load full rubygems if an unimplemented method is called" do
  #   Gem.should be_minigems
  #   lambda { Gem.source_index }.should_not raise_error(NoMethodError)
  #   Gem.should_not be_minigems
  # end
  
  # it "should load full rubygems if a missing Gem constant is referenced" do
  #   Gem.should be_minigems
  #   lambda { Gem::Builder }.should_not raise_error(NameError)
  #   Gem.should_not be_minigems
  # end
  
end