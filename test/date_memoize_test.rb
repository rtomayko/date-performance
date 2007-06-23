require 'date/performance'
require 'date/memoize'
require 'test/unit'

class DateMemoizeTest < Test::Unit::TestCase

  def setup
    Date::Memoize.install!
  end

  def test_installed_by_default
    assert Date::Memoize.installed?, "didn't install when required"
  end

  def test_civil_memoization
    expected = Date.new_without_memoization(2002, 03, 22)
    actual = Date.new(2002, 03, 22)
    assert_not_same expected, actual
    assert_equal expected, actual
    expected, actual = actual, Date.new(2002, 03, 22)
    assert_same expected, actual
    assert_equal expected, actual
  end

  def test_strptime_memoization
    Date::Memoize.uninstall!
    expected = Date.strptime('2002-03-22', '%Y-%m-%d')
    Date::Memoize.install!
    actual = Date.strptime('2002-03-22', '%Y-%m-%d')
    assert_equal expected, actual
    assert_not_same expected, actual
    expected, actual = actual, Date.strptime('2002-03-22', '%Y-%m-%d')
    assert_same expected, actual
    assert_equal expected, actual
  end

  def test_parse_memoization
    Date::Memoize.uninstall!
    expected = Date.parse('2002-03-22')
    Date::Memoize.install!
    actual = Date.parse('2002-03-22')
    assert_equal expected, actual
    assert_not_same expected, actual, "With (#{actual.to_s}) and without (#{expected.to_s}) memoization are the same (#{actual.object_id}, #{expected.object_id})."
    expected, actual = actual, Date.parse('2002-03-22')
    assert_same expected, actual
    assert_equal expected, actual
  end

  def test_uninstall_is_detected
    Date::Memoize.uninstall!
    assert !Date::Memoize.installed?, "didn't uninstall or uninstall not detected properly"
    methods = Date.methods.select{|m| m.to_s =~ /_without_memoization$/}
    flunk "Memoization methods not removed: #{methods.inspect}" if methods.any?
    vars = Date.send(:instance_variables).select{|v| v.to_s =~ /^@__memoized_/}
    flunk "Memoization instance variables not removed: #{vars.inspect}" if vars.any?
  end

  def test_uninstall_removes_methods
    Date::Memoize.uninstall!
    methods = Date.methods.select{|m| m.to_s =~ /_without_memoization$/}
    assert_equal 0, methods.length, "Memoization methods not removed: #{methods.inspect}"
  end

  def test_uninstall_removes_instance_variables
    Date::Memoize.uninstall!
    vars = Date.send(:instance_variables).select{|v| v.to_s =~ /^@__memoized_/}
    assert_equal 0, vars.length, "Memoization instance variables not removed: #{vars.inspect}"
  end

end
