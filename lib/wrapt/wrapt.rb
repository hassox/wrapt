# Wrapt is a specialised middleware that wraps content in a given layout
#
# Wrapt injects an object into the environment which you can use to provide content to.
# When you're done, return the wrapt object as the body for your request and the layout will be applied.
#
# You can pass variables through the rack through the environment via the 'request.variables' key which will be a hash like object
#
# @example
#
# def call(e)
#   wrapt = e['layout']
#   wrapt.content = "Here's some content"
#   [200, {"Content-Type" => "text/html"}, wrapt]
# end
#
# Produces:
#   <!-- wrapping layout -->
#     Here's some content
#   <!-- footer wrapping layout -->
#
# A layout directory may be specified that points to any layouts that are to be used.
#
# A format may be specified for the layout if it is intended not to use html.
# Simply tell wrapt the format to use via the +format=+ method.
#
# If you don't want a layout, simply don't use the wrapt object.
class Wrapt
  def initialize(app, opts={})
    @app = app
    @master = false
    yield self if block_given?
  end

  def master!
    @master = true
  end

  def master?
    !!@master
  end

  def call(env)
    env['request.variables'] ||= Hashie::Mash.new
    layout = env['layout']
    if !layout || (layout && !layout.master?)
      env['layout'] = Layout.new(self, env)
    end
    r = @app.call(env) # just return what the app returns… If it wants a layout, it will return it.
    env['layout'] = layout if layout
    r
  end

  def layout_dirs=(dirs)
    @layout_dirs = Array.new(dirs).flatten
  end

  def layout_dirs
    @layout_dirs ||= [File.join(Dir.pwd, "layouts")]
  end

  def default_template
    @default_template ||= "application"
  end

  def default_template=(name)
    @default_template = name
  end

  def default_format=(format)
    @default_format = format
  end

  def default_format
    @default_format ||= :html
  end

  def template(name, opts={})
    format = opts.fetch(:format, default_format)
    template_name = template_name_and_format_glob(name,format, opts)

    template = _template_cache[template_name]
    return template if template

    file = nil
    layout_dirs.detect do |dir|
      file = Dir[File.join(dir, template_name)].first
    end
    if file.nil?
      nil
    else
      _template_cache[template_name] = Tilt.new(file)
    end
  end

  private
  def template_name_and_format(name, format, opts)
    "#{name}.#{format}"
  end

  def template_name_and_format_glob(name, format, opts)
    "#{template_name_and_format(name,format,opts)}.*"
  end

  def _template_cache
    @cache ||= {}
  end
end

