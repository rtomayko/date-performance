$: << 'lib'
require 'date'
# require 'date/fast'

def profile_new_civil(iterations=1000)
  iterations.times do |i|
    Date.new(1912, 6, 23)
  end
end

def profile_new_jd(iterations=1000)
  jd = Date.civil_to_jd(1912, 6, 23, Date::ITALY)
  iterations.times do |i|
    Date.jd(jd)
  end
end

def profile_comparison(iterations=1000)
  d1, d2 = Date.new(1912, 6, 23), Date.new(1906, 4, 28)
  iterations.times do |i|
    d1 == d2
  end
end

def profile_greater_than(iterations=1000)
  d1, d2 = Date.new(1912, 6, 23), Date.new(1906, 4, 28)
  iterations.times do |i|
    d1 > d2
  end
end

def profile_strftime(iterations=1000)
  date = Date.new(1912, 6, 23)
  iterations.times do |i|
    date.strftime
  end
end

def profile_strftime_after_new(iterations=1000)
  iterations.times do |i|
    Date.new(1912, 6, 23).strftime
  end
end

def profile_strptime(iterations=1000)
  iterations.times do |i|
    Date.strptime '06/23/1912', '%m/%d/%Y'
  end
end

def run_profiles
  require 'benchmark'
  all_methods = private_methods.select{|m| m =~ /^profile_/}.map{|m| m.sub /^profile_/, '' }.sort
  selected_methods = 
    if ARGV.empty?
     all_methods
   else
     ARGV
   end
  # warm-up
  selected_methods.each {|method| send "profile_#{method}", 1 }
  selected_methods.each do |method|
    puts method
    puts Benchmark.measure{ send "profile_#{method}", 10000 }
  end
end

run_profiles
