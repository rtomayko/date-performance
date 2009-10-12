require 'date'

# Loading this file is not idemponent and can cause damage when loaded twice.
# Fail hard and fast.
fail "Date::Performance already loaded." if defined? Date::Performance

class Date

  # The Date::Performance module is present when the performance enhacing extension 
  # has been loaded. It serves no other purpose.
  module Performance
    VERSION = "0.4.8"
  end

  # The extension replaces Date#strftime but falls back on the stock version when
  # strftime(3) cannot handle the format.
  alias_method :strftime_without_performance, :strftime

  class << self
    # Ruby 1.8.6 introduced Date.new! and the extension uses it. The method was 
    # called new0 in <= 1.8.5.
    alias_method :new!, :new0 unless Date.respond_to?(:new!)

    # The extension replaces Date.strptime but falls back on the stock version when 
    # strptime(3) can't handle the format.
    alias_method :strptime_without_performance, :strptime
  end

end

# Load up the extension but bring the Date class back to its original state
# if the extension fails to load properly.
begin
  require 'date_performance.so'
rescue
  class Date
    remove_const  :Performance
    remove_method :strftime_without_performance
    class << self
      remove_method :strptime_without_performance
    end
  end
  raise
end
