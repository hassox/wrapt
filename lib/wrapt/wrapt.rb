# Wrapt is a specialised middleware that wraps content in a given layout
#
# Wrapt injects an object into the environment which you can use to provide content to.
# When you're done, return the wrapt object as the body for your request and the layout will be applied.
#
# You can pass variables through the rack through the environment via the 'request.variables' key which will be a hash like object
#
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

  IGNORE_LAYOUT = lambda{|e| false}

  # Wrapt is initialized as middleware in a Rack stack
  # @block the wrapt instance is passed to the block for further configuration
  #   You can set layout template directories,
  #   Default format, default layout or declare the layouter as the "master"
  #
  # @see Wrapt#master!
  # @see Wrapt#layout_dirs
  # @see Wrapt#default_format
  # @see Wrapt#default_template
  def initialize(app)
    @app = app
    @master = false
    yield self if block_given?
  end

  # Declare this wrapt instance to be the master
  # This will mean that all downstream wrapt instances will be ignored
  # and this layouter will be used for the entire downstream graph
  #
  # @api public
  def master!
    @master = true
  end

  # Checks to see if this layouter is a master
  # @api private
  def master?
    !!@master
  end

  # Wrapt allows you to ignore layouts from the client side.
  #
  # This may be useful for esi, or ajax, where you want the content, but not the layout
  #
  # @block Provide a block to act as a guard for ignoring the layout from the client side.
  # The block is provided with the Rack environment from the request
  #
  # @see Wrapt#ignore_layout?
  # @api public
  def ignore_layout(&block)
    @ignore_layout = block
  end

  # Checks to see if the layout should be ignored for this request.
  #
  # @example
  #   use Wrapt do |wrapt|
  #     wrapt.ignore_layout do |env|
  #       request = Rack::Request.new(env)
  #       params["apply_layout"] == false
  #     end
  #   end
  #   run MyApp
  #
  # GET "/?apply_layout=false" # Layout is ignored
  #
  # @see Wrapt#ignore_layout
  # @api public
  def ignore_layout?(env)
    @ignore_layout ||= IGNORE_LAYOUT
    @ignore_layout.call(env)
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

  # Set the layout directories
  # These are the directories that wrapt will inspect (in order) when it attempts to find the given layouts
  # @param [Array] dirs An array of directories where wrapt should look to find the layout templates
  # @api public
  def layout_dirs=(dirs)
    @layout_dirs = Array.new(dirs).flatten
  end

  # Provides access to the directories where wrapt will inspect to find the layouts
  # @api public
  # @return [Array] An array of directories that wrapt will look in for template files
  def layout_dirs
    @layout_dirs ||= begin
      [
        File.join(Dir.pwd, "layouts"),
        File.join(Dir.pwd, "views/layouts"),
        File.join(Dir.pwd, "app/views/layouts")
      ]
    end
  end

  # The default template name wrapt will use when none is specified
  # @api public
  # @return [String] default template name
  def default_template
    @default_template ||= "application"
  end

  # set the default template
  # @api public
  # @see Wrapt#default_template
  def default_template=(name)
    @default_template = name
  end

  # Get the default format that has been defined for the instance of wrapt
  #
  # The format is used by default in the template file name.
  # The default naming convention for the template name is
  #   <template_name>.<format>.<template_type>
  #
  # @example
  #   application.html.haml
  # @api public
  def default_format
    @default_format ||= :html
  end

  # Set the default format for this instance of wrapt
  # @see Wrapt#default_format
  # @api public
  def default_format=(format)
    @default_format = format
  end

  # Fetches the named template with any given options
  #
  # @param [String|Symbol] The template name to fetch
  # @param [Hash] opts
  # @option opts [String|Symbol] :format Provide the format for the template that will be used
  # @return [Tilt::Template|NilClass] A template file to use to render the layout
  # @api public
  def template(name, opts={})
    format = opts.fetch(:format, default_format)
    template_name = template_name_and_format_glob(name,format, opts)

    return _template_cache[template_name] if _template_cache[template_name]

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
  # Calculates the relative filename of the template
  # @param [String|Symbol] name The template name
  # @param [String|Symbol] format The template format
  # @param [Hash] opts An options hash that is provided to the template method
  #
  # @see Wrapt#template
  # @api overwritable
  def template_name_and_format(name, format, opts)
    "#{name}.#{format}"
  end

  # Provides a glob from the template_name_and_format to look up the file from
  # @api private
  def template_name_and_format_glob(name, format, opts)
    "#{template_name_and_format(name,format,opts)}.*"
  end

  # A cache for the template files so that they're only loaded once
  # @api private
  def _template_cache
    @cache ||= {}
  end
end

