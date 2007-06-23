# See Date::Memoize.

require 'date'
require 'date/performance'

class Date #:nodoc:

  # Adds memoization to Date. This can speed things up significantly in cases where a lot 
  # of the same Date objects are created.
  module Memoize

    # Memoized version of Date::strptime.
    def strptime(str='-4712-01-01', fmt='%F', sg=ITALY)
      @__memoized_strptime_dates[ [ str, fmt, sg ] ]
    end

    # Memoized version Date::parse.
    def parse(str='-4712-01-01', comp=false, sg=ITALY)
      @__memoized_parse_dates[ [ str, comp, sg ] ]
    end

    # Memoized version of Date::civil.
    def civil(y=-4712, m=1, d=1, sg=ITALY)
      @__memoized_civil_dates[ [ y, m, d, sg ] ]
    end

    alias_method :new, :civil

  public

    # The methods we'll be replacing on the Date singleton.
    def self.methods_replaced
      [ :new, :civil, :strptime, :parse ]
    end

    # Overridden to move the existing methods out of the way before copying this module's
    # methods.
    def self.extend_object(base)
      singleton = (class<<base;self;end)
      methods_replaced.each do |method|
        singleton.send :alias_method, "#{method}_without_memoization", method
        singleton.send :remove_method, method
      end
      base.send :instance_variable_set, :@__memoized_civil_dates, 
        Hash.new{|h,key| h[key]=Date.new_without_memoization(*key)}
      base.send :instance_variable_set, :@__memoized_strptime_dates, 
        Hash.new{|h,key| h[key]=Date.strptime_without_memoization(*key)}
      base.send :instance_variable_set, :@__memoized_parse_dates, 
        Hash.new{|h,key| h[key]=Date.parse_without_memoization(*key)}
      super
    end

    # Removes memoization methods from singleton of the class provided.
    def self.unextend_object(base)
      singleton = (class<<base;self;end)
      methods_replaced.each do |method|
        singleton.send :alias_method,  method, "#{method}_without_memoization"
        singleton.send :remove_method, "#{method}_without_memoization"
      end
      base.send :remove_instance_variable, :@__memoized_civil_dates
      base.send :remove_instance_variable, :@__memoized_strptime_dates
      base.send :remove_instance_variable, :@__memoized_parse_dates
      base
    end

    # Is Date memoization currently installed and active?
    def self.installed?
      Date.respond_to? :civil_without_memoization
    end

    # Extend the Date class with memoized versions of +new+ and +civil+ but only if 
    # memoization has not yet been installed.
    def self.install!
      Date.extend self unless installed?
    end

    # Remove memoized methods and free up memo cache. This method is idempotent.
    def self.uninstall!
      unextend_object Date if installed?
    end

  end

  Memoize.install!

end
