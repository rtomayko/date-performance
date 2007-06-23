require 'date/performance'
require 'test/unit'

class ExtensionTest < Test::Unit::TestCase

  def test_civil_to_jd
    assert_equal 2419577, Date.civil_to_jd(1912, 6, 23)
    assert_equal 2419577, Date.civil_to_jd(1912, 6, 23, Date::GREGORIAN)
  end

  def test_jd_to_civil
    expected = [ 1912, 6, 23 ]
    assert_equal expected, Date.jd_to_civil(2419577)
    assert_equal expected, Date.jd_to_civil(2419577, Date::GREGORIAN)
  end

  def test_jd_to_ajd
    expected = Rational(4839153, 2)
    assert_equal expected, Date.jd_to_ajd(2419577)
    assert_equal expected, Date.jd_to_ajd(2419577, 0)
    assert_equal expected, Date.jd_to_ajd(2419577, 0, 0)
  end

  def test_ajd_to_jd
    ajd = Rational(4839153, 2)
    expected = [ 2419577, Rational(1, 2) ]
    assert_equal(expected, Date.ajd_to_jd(ajd))
    assert_equal(expected, Date.ajd_to_jd(ajd, 0))
  end

  def test_new
    expected = Date.new!(Rational(4839153, 2))
    assert_equal expected, Date.new(1912, 6, 23)
    assert_equal expected, Date.new(1912, 6, 23, Date::ITALY)
  end

  def test_new_raises_argument_error
    assert_raise ArgumentError do
      Date.new(1912, 25, 55)
    end
  end

  def test_civil_cached_on_new
    date = Date.new(1912, 6, 23)
    assert_not_nil(expected = date.send(:instance_variable_get, :@__civil__))
    assert_equal expected, date.civil
  end

  def test_civil_cached_on_new!
    date = Date.new!(Rational(4839153, 2))
    assert !date.send(:instance_variables).include?('@__civil__'), '@__civil__ ivar should not exist'
    assert_equal([1912, 6, 23], date.civil)
    assert_equal([1912, 6, 23], date.instance_variable_get(:@__civil__))
  end

  def test_sys_strftime
    date = Date.new(1912, 6, 23)
    assert_equal "1912-06-23", date.sys_strftime
    assert_equal "06/23/1912", date.sys_strftime("%m/%d/%Y")
  end

  def test_sys_strptime
    assert_equal Date.new(1912, 6, 23), Date.sys_strptime("1912-06-23")
    assert_equal Date.new(1912, 6, 23), Date.sys_strptime("1912-06-23", "%Y-%m-%d")
  end

  # This falls back on Ruby's strptime on BSD systems because BSD's strptime doesn't
  # handle years before 1900.
  def test_strptime_fallback
    assert_equal Date.new(1, 1, 1), Date.strptime("01/01/0001", "%m/%d/%Y")
  end

  # Make sure we're not breaking DateTime
  def test_datetime
    datetime = DateTime.parse("1912-06-23T04:20:37Z")
    assert_equal 1912, datetime.year
    assert_equal 6, datetime.month
    assert_equal 23, datetime.day
    assert_equal 4, datetime.hour
    assert_equal 20, datetime.min
    assert_equal 37, datetime.sec
  end

  def test_new_fails_with_nils
    assert_raise(TypeError) { Date.new(nil, nil, nil) }
    assert_raise(TypeError) { Date.new(2007, nil, nil) }
    assert_raise(TypeError) { Date.new(2007, 9, nil) }
  end

  def test_strftime_with_weekday
    assert_equal "Monday", Date.new(2007, 1, 1).strftime("%A")
  end

  def test_strftime_with_datetime
    DateTime.new
  end

end
