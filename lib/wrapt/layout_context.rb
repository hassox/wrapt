class Wrapt
  # The context used within the layouts
  # Anything that is required to be avaible in the view context should be included into the Helpers module, or the LayoutContext
  # @see Wrapt::Helpers
  class LayoutContext
    attr_reader :env
    include Tilt::CompileSite
    include Helpers

    def initialize(env)
      @env = env
    end

    def request
      @request = Rack::Request.new(env)
    end
  end
end
