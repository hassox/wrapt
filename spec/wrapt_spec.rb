require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Wrapt do
  before(:all) do
    unless defined?(SpecWraptApp)
      SpecWraptApp = lambda do |e|
        msg = $message || "ok"
        layout = e['layout']

        out = if layout
          layout.content = msg
          layout
        else
          msg
        end

        Rack::Response.new(out).finish
      end
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
      @wrapt = Wrapt.new(SpecWraptApp){|w| w.default_template = "wrapper"}
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

    it "should use the 'application' template by default" do
      wrapt = Wrapt.new(SpecWraptApp)
      wrapt.default_template.should == "application"
    end

    it "should allow me to set my own default template" do
      @wrapt.default_template = "my_template"
      @wrapt.default_template.should == "my_template"
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
      @wrapt = Wrapt.new(SpecWraptApp){|w| w.default_template = :wrapper}
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

    it "should allow me to define an upstream wrapt as the master, meaning it won't be replaced by any downstream ones" do
      env = Rack::MockRequest.env_for("/")
      @wrapt.master!
      wrapt2 = Wrapt.new(SpecWraptApp) do |wrapt|
        wrapt.default_format = :jsonp
        wrapt.default_template = :wrapper
      end

      @wrapt.call(env)
      r = wrapt2.call(env)

      layout = env['layout']
      result = r[2].body.to_s
      result.should_not include("{ content")
      layout.wrapt.should == @wrapt
    end

    it "should allow me to define an upstream wrapt and a downstream, and have the downstream one work downstream and the upstream one work upstream" do
      env = Rack::MockRequest.env_for("/")

      wrapt2 = Wrapt.new(SpecWraptApp) do |wrapt|
        wrapt.default_format = :jsonp
        wrapt.default_template = :wrapper
        wrapt.layout_dirs = layouts_dirs
      end

      s = @wrapt.call(env)
      r = wrapt2.call(env)

      result = r[2].body.to_s
      result.should include("{ content")
      layout = env['layout']
      layout.wrapt.should == @wrapt
    end
  end

  describe Wrapt::Layout do
    before(:all) do
      unless defined?(WraptApp)
        WraptApp = lambda do |e|
          wrapt = e['layout']
          wrapt.content = $msg || "ok"
          Rack::Response.new(wrapt).finish
        end
      end
    end

    before do
      @wrapt = Wrapt.new(WraptApp) do |w|
        w.layout_dirs = layouts_dirs
        w.default_template = "wrapper"
      end
      @env = Rack::MockRequest.env_for("/")
      @wrapt.call(@env)
      @layout = @env['layout']
    end

    describe "on demand" do
      it "should wrap content on demand" do
        result = @layout.wrap("Hi There")
        result.should include("Hi There")
        result.should include("<h1>Wrapper Template</h1>")
      end

      it "should wrap the content with a different layout" do
        result = @layout.wrap("Hi There", :layout => :other)
        result.should include("Other Template")
        result.should include("Hi There")
      end

      it "should wrap the content with a different format" do
        result = @layout.wrap("Hi There", :format => :xml)
        result.should include("<h1>Wrapper Template XML</h1>")
        result.should include("Hi There")
      end
    end

    it "should allow me to set the content" do
      @layout.content = "This is some content of mine"
      result = @layout.map.join
      result.should include("This is some content of mine")
      result.should include("<h1>Wrapper Template</h1>")
    end

    it "should allow me to set the format of a request" do
      @layout.format = :xml
      result = @layout.map.join
      result.should include("<h1>Wrapper Template XML</h1>")
    end

    it "should ask the middleware for the format if no format is set" do
      @wrapt = Wrapt.new(WraptApp) do |w|
        w.layout_dirs = layouts_dirs
        w.default_template = "wrapper"
        w.default_format   = :jsonp
      end
      @env = Rack::MockRequest.env_for("/")
      @wrapt.call(@env)
      @layout = @env['layout']
      @layout.content = "json data"
      result = @layout.map.join
      result.should include("{ content: 'json data' }")
    end

    it "should provide me with the wrapped layout with to_s" do
      @layout.to_s.should == @layout.map.join
    end
  end
end
