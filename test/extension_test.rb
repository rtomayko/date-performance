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

  def test_strptime_str_input_handling
    assert_raise(TypeError) { Date.strptime(19120623, '%Y%m%d') }
    assert_raise(TypeError) { Date.strptime(nil, '%Y%m%d') }
  end

  def test_strptime_fmt_input_handling
    assert_raise(TypeError) { Date.strptime('19120623', 12345) }
    assert_raise(TypeError) { Date.strptime('19120623', nil) }
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
    dt = DateTime.new(2007, 1, 1, 4, 20, 00)
    assert_equal "2007-01-01T04:20:00+00:00", dt.strftime("%FT%T%:z")
  end

  def test_constructor_with_negative_days
    #leap year
    month_ends = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    (1..12).each do |m|
      d = Date.new(2008, m, -1)
      assert_equal d.day, month_ends[m-1]
    end
    #normal year
    month_ends = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    (1..12).each do |m|
      d = Date.new(2009, m, -1)
      assert_equal d.day, month_ends[m-1]
    end
    #before calendar reform for Italy
    month_ends = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    (1..12).each do |m|
      d = Date.new(1581, m, -1)
      assert_equal d.day, month_ends[m-1]
    end
  end

  def test_date_comparisons
    #regular Date class comparison
    d = Date.new(2008, 1, 1)
    366.times do |i|
        assert_equal( 0, d+i <=> d+i )
        assert_equal(-1, d+i <=> d+i+1 )
        assert_equal( 1, d+i+1 <=> d+i )
    end

    #DateTime comparison
    dt1 = DateTime.new(2006,1,1,12,15,30)
    dt2 = DateTime.new(2006,1,1,12,15,31)
    dt3 = DateTime.new(2006,1,1,12,15,29)
 
    assert_equal( 0, DateTime.new(2006,1,1,12,15,30) <=> dt1 )
    assert_equal( 1, dt1 <=> dt3 )
    assert_equal( -1, dt1 <=> dt2 )

    #comparison with some random type
    assert_equal nil, dt1 <=> "foo"

    #comparison with Fixnum that represents ajd
    assert_equal(-1, d <=> d.ajd.numerator )
  end

end
