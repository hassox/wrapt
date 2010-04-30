class Wrapt
  # The context used within the layouts
  # Anything that is required to be avaible in the view context should be included into the Helpers module, or the LayoutContext
  # @see Wrapt::Helpers
  class LayoutContext
    include Tilt::CompileSite
    include Helpers
  end
end
