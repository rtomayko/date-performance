load 'misc/asciidoc.rake'
load 'misc/project.rake'

Project.new "Date::Performance" do |p|
  p.package_name = 'date-performance'
  p.version_file = 'lib/date/performance.rb'
  p.summary = "Adds some semblance of performance to Ruby's core Date class."
  p.project_url = "http://tomayko.com/src/date-performance/"
  p.extra_files.include "ext/**/*.{rb,c,h}", "AUTHORS", "BENCHMARKS"
  p.configure_package {|spec| spec.extensions = FileList["ext/**/extconf.rb"].to_a }
  p.author = 'Ryan Tomayko <rtomayko@gmail.com>'

  p.remote_dist_location   = "tomayko.com:/dist/#{p.package_name}"
  p.remote_branch_location = "tomayko.com:/src/#{p.package_name}.git"
  p.remote_doc_location    = "tomayko.com:/src/#{p.package_name}"
end

task :default => [ :compile, :test ]

file 'ChangeLog' => FileList['.bzr/*'] do |f|
  sh "bzr log -v --gnu > #{f.name}"
end

file 'doc/index.txt' => 'README.txt' do |f|
  cp 'README.txt', f.name
end

file 'doc/changes.html' => 'ChangeLog'

CLEAN.include [ "ext/*.{o,bundle}", "lib/*.{bundle,so,dll}" ]
CLOBBER.include [ "ext/Makefile" ]

if File.exist? 'misc/date-1.8.5'
  desc "Run unit tests with Date from Ruby 1.8.5"
  Rake::TestTask.new 'test:ruby185' do |t|
    t.libs << "test"
    t.libs << "misc/date-1.8.5"
    t.test_files = FileList['test/*_test.rb']
    t.verbose = true
  end
end

task 'benchmark.without' do |t|
  verbose false do
    puts '== WITHOUT EXTENSION ==========================='
    ruby "-Ilib test/benchmarks.rb"
  end
end

task 'benchmark.with' do |t|
  verbose false do
    puts '== WITH EXTENSION =============================='
    ruby "-Ilib -rdate/performance test/benchmarks.rb"
  end
end

desc "Run benchmarks"
task :benchmark => [ 'benchmark.without', 'benchmark.with' ]

# Extension =======================================================================================

DLEXT = Config::CONFIG['DLEXT']

directory "lib"

desc "Build the extension"
task "date_performance" => [ "lib/date_performance.#{DLEXT}" ]

file "ext/Makefile" => FileList[ "ext/*.{c,h,rb}" ] do
  Dir.chdir("ext") { ruby "extconf.rb" }
end

file "ext/date_performance.#{DLEXT}" => FileList["ext/*.c", "ext/Makefile"] do |f|
  Dir.chdir("ext") { sh "make" }
end

file "lib/date_performance.#{DLEXT}" => [ "ext/date_performance.#{DLEXT}" ] do |t|
  cp "ext/date_performance.#{DLEXT}", t.name
end

desc "Compiles all extensions"
task :compile => [ "lib/date_performance.#{DLEXT}" ]
