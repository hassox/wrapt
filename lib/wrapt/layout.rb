class Wrapt
  class Layout
    include Enumerable
    attr_accessor :wrapt, :env, :template_name, :format
    attr_reader   :request

    def initialize(wrapt, env)
      @env = env
      @wrapt = wrapt
      @request = Rack::Request.new(@env)
      @content_for = Hashie::Mash.new
      @ignore_layout = nil
    end

    # Is the wrapt instance that created this layouter set as a master?
    # @see Wrapt#master?
    # @api public
    def master?
      @wrapt.master?
    end

    # Check to see if there is a template of a given name and options
    # for this layouter.
    #
    # @see Wrapt#template
    # @api public
    def template_name?(name, opts = {})
      !!@wrapt.template(name, opts)
    end

    # Gets the format that this layouter has been set to.
    # Defaults to the default_format of the wrapt instance
    #
    # May be set with Wrapt::Layout#format=
    #
    # @see Wrapt#default_format
    def format
      @format ||= @wrapt.default_format
    end

    # allows you to set the ignore_layout block for just this request (and anythin downstream)
    #
    def ignore_layout(&block)
      @ignore_layout = block
    end

    # Gets the template name that this layouter has.
    # Defaults to the wrapts instances default_template
    #
    # May be set with Wrapt::Layout#default_template=
    #
    # @see Wrapt.default_template
    def template_name
      @template_name ||= @wrapt.default_template
    end

    # Wraps the given content into the layout using the same base
    # as the layouter currently has
    #
    # @params [String] content The content to form the main body of the layout
    # @params [Hash] opts an options hash
    # @option opts [String|Symbol] :layout the name of a layout template to use
    # @option opts [String|Symbol] :format the format of the layout template to use
    # @api public
    def wrap(content, opts={})
      layout = self.dup

      layout.format         = opts[:format] if opts[:format]
      layout.template_name  = opts[:layout] if opts[:layout]

      layout.content = content
      layout.render_layout(false)
    end

    def dup
      dupped = super
      dupped.instance_variable_set('@content_for', Hashie::Mash.new)
      dupped
    end

    # Set the content for the layout for the given label
    # @param [Symbol] label The label to identify the content to insert
    # @param [String] content The content to set for this label
    # @block The return of the block is used as preference.  Block is optional
    #
    # @see Wrapt::Layout#content_for
    # @api public
    def set_content_for(label = :content, content = nil)
      if block_given?
        content = block.call
      end

      content_for[label] = content
    end

    # Provides access to the content_for hash.
    # Content may be accessed for concatination etc
    #
    # When using content_for you can provide different contents for you layouts.
    # The default content label is :content
    # @example
    #   # In your application
    #   layout = env['layout']
    #   layout.set_content_for(:foo, "Foo Content")
    #   layout.content = "Normal Content"
    #
    #
    #   # In the layout
    #   <%= yield %>          <-- inserts the content labeled :content
    #   <%= yield :content %> <-- insert the content labeled :content
    #   <%= yield :foo %>     <-- insert the content labled :foo
    #
    # @api public
    def content_for
      @content_for
    end

    # Set the main content for the layout
    # @api public
    def content=(content)
      set_content_for(:content, content)
    end

    # An easy method to get the wrapped results
    # @api public
    def to_s
      map.join
    end

    # The interface for rack.
    # @api public
    def each
      ignore = if @ignore_layout
        @ignore_layout.call(env)
      else
        @wrapt.ignore_layout?(env)
      end

      result = render_layout(ignore)
      yield result
      result
    end

    # @api private
    def render_layout(ignore_layout = false)
      return content_for[:content] if ignore_layout

      opts = {}
      opts[:format]   ||= format
      template = template_name

      template = @wrapt.template(template, opts)

      output = if template
        template.render(LayoutContext.new(env)) do |*args|
          label = args.first || :content
          content_for[label]
        end
      else
        content_for[:content]
      end
      output
    end
  end
end
