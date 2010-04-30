require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Wrapt do
  before(:all) do
    unless defined?(SpecWraptApp)
      SpecWraptApp = lambda{|e| Rack::Response.new("ok").finish}
    end
  end

  def layouts_dirs
    [File.join(File.dirname(__FILE__), "layouts")]
  end

  def alt_layouts_dirs
    [File.join(File.dirname(__FILE__), "alt_layouts")]
  end

  describe "defining the middleware" do
    before do
      @wrapt = Wrapt.new(SpecWraptApp)
    end

    it "should allow me to define the directories to use to find the templates" do
      w = Wrapt.new(SpecWraptApp)
      w.layout_dirs = layouts_dirs
      w.layout_dirs.should == layouts_dirs
    end

    it "should allow me to set the layout_dirs in the middleware" do
      w = Wrapt.new(SpecWraptApp) do |wrapt|
        wrapt.layout_dirs = layouts_dirs
      end
      w.layout_dirs.should == layouts_dirs
    end

    it "should provide me with the Dir.pwd/layouts as the default location to find layouts" do
      @wrapt.layout_dirs.should == [File.join(Dir.pwd, "layouts")]
    end

    it "should allow me to set a default format" do
      @wrapt.default_format = :json
      @wrapt.default_format.should == :json
    end

    it "should have a default format of :html" do
      @wrapt.default_format.should == :html
    end

    it "should provide a hook for me to work out the format to use"
  end

  describe "managing templates" do
    before do
      @wrapt = Wrapt.new(SpecWraptApp) do |w|
        w.layout_dirs = layouts_dirs
      end
    end

    it "should find me a template of a given name with the format for the current request" do
      @wrapt.template(:first).should be_a_kind_of(Tilt::Template)
    end

    it "should return nil when there is no format found of that name" do
      @wrapt.template("not_a_real_template").should be_nil
    end

    it "should return nil when there is no format found of that format" do
      @wrapt.template(:first, :format => :no_real_forma).should be_nil
    end

    it "should search all the layout directories provided to return the template" do
      @wrapt = Wrapt.new(SpecWraptApp) do |w|
        w.layout_dirs = layouts_dirs + alt_layouts_dirs
      end
      @wrapt.template(:second).should be_a_kind_of(Tilt::Template)
      @wrapt.template(:second).render.should match(/Second \(Alternative\)/)
    end
  end

  describe "injecting into the environment" do
    before do
      @wrapt = Wrapt.new(SpecWraptApp)
    end

    it "should inject a Wrapt::Layout object into the environment" do
      env = {}
      @wrapt.call(env)
      env['layout'].should be_an_instance_of(Wrapt::Layout)
    end

    it "should make sure there's a request.variables key in the env" do
      env = {}
      @wrapt.call(env)
      vars = env['request.variables']
      vars.should_not be_nil
      vars.should respond_to(:[])
      vars.should respond_to(:[]=)
      vars.should respond_to(:clear)
      vars.should respond_to(:keys)
    end

    it "should allow me to define an upstream wrapt as the master, meaning it won't be replaced by any downstream ones"
  end

  describe Wrapt::Layout do
    it "should wrap content on demand"
    it "should allow me to set the content"
    it "should allow me to set the format of a request"
    it "should ask the middleware for the format if no format is set"
    it "should provide me with the wrapped layout with to_s"
    it "should provide me with the layout via each"
  end
end
