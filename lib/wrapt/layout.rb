class Wrapt
  class Layout
    include Enumerable
    attr_accessor :template_name, :format, :wrapt

    def initialize(wrapt, env)
      @wrapt = wrapt
      opts.keys.each do |k,v|
        send(k, v)
      end
    end

    def master?
      @wrapt.master?
    end

    def format
      @format ||= @wrapt.default_format
    end

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
      layout.map.join
    end

    def content=(content)
      @content = content
    end

    def to_s
      map.join
    end

    def each
      opts = {}
      opts[:format]   ||= format
      template = template_name

      template = @wrapt.template(template, opts)

      output = if template
        template.render{|*args| @content }
      else
        @content
      end
      yield output
      output
    end
  end
end
