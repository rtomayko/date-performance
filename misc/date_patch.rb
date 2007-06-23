require 'date'

Date.new(1912, 6, 23)

def benchmarks
  require 'benchmark'
  Benchmark.bm 50 do |x|
    x.report "new (slow):" do
      10000.times { Date.new(1912, 6, 23) }
    end
    x.report "jd_to_ajd (slow):" do
      10000.times { Date.jd_to_ajd(2419577, 0, 0) }
    end
    require 'date_fast.so'
    x.report "new (C):" do
      10000.times { Date.new(1912, 6, 23) }
    end
    x.report "jd_to_ajd (C):" do
      10000.times { Date.jd_to_ajd(2419577, 0, 0) }
    end
  end
end

def debug_extension
  Date::Fast.install
  p Date.jd_to_civil(2419577, Date::ITALY)
  require 'date_fast.so'
  p Date.jd_to_civil(2419577, Date::ITALY)
end

benchmarks
