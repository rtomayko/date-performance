require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'fileutils'
include FileUtils

NAME = "Date::Performance"
PACKAGE_NAME = 'date-performance'
SUMMARY = "Adds some semblance of performance to Ruby's core Date class."
VERS = ENV['VERSION'] || eval(`grep 'VERSION =' < lib/date/performance.rb`.split(' = ').last)
MAJOR_VERSION, MINOR_VERSION, REV = VERS.split('.')
NEXT_VERSION = ENV['VERSION'] || [ MAJOR_VERSION, MINOR_VERSION, REV.to_i + 1 ].join('.')
CLEAN.include [ "ext/*.{o,bundle}", "lib/*.{bundle,so,dll}" ]
CLOBBER.include [ "ext/Makefile" ]

task :info do
  puts "#{NAME}/#{VERS}"
  puts SUMMARY
end

task :default => [ :compile, :units ]

desc "Run unit tests and benchmarks"
task :test => [ :units, :units_185 ]

desc "Run unit tests"
Rake::TestTask.new :units do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

if File.exist? 'misc/date-1.8.5'
  desc "Run unit tests with Date from Ruby 1.8.5"
  Rake::TestTask.new :units_185 do |t|
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

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.main = "README"
  rdoc.title = "Date::Performance Documentation"
  rdoc.rdoc_files.add ['README', 'ChangeLog', 'COPYING', 'lib/**/*.rb', "AUTHORS"]
end

spec =
  Gem::Specification.new do |s|
    s.name = PACKAGE_NAME
    s.version = VERS
    s.summary = SUMMARY
    s.description = SUMMARY
    s.platform = Gem::Platform::RUBY
    s.author = "Ryan Tomayko"
    s.email = 'rtomayko@gmail.com'
    s.homepage = 'http://code.tomayko.com/browser/date-performance'
    s.files = 
      %w(COPYING README Rakefile ChangeLog AUTHORS) +
      Dir["lib/**/*.rb"] +
      Dir["test/**/*.rb"] +
      Dir["ext/**/*.{rb,c,h}"]
    s.require_path = "lib"
    s.extensions = FileList["ext/**/extconf.rb"].to_a
    s.has_rdoc = true
    s.extra_rdoc_files = ["README", "ChangeLog", "COPYING", "AUTHORS"]
    s.test_files = FileList["test/*_test.rb"]
  end

Rake::GemPackageTask.new(spec) do |p|
  p.need_tar = true
  p.gem_spec = spec
end

task :package => [ :clean ]

task :publish => [ "pkg/#{PACKAGE_NAME}-#{VERS}.gem", "pkg/#{PACKAGE_NAME}-#{VERS}.tgz" ] do |t|
  gem_path = "~naeblis/www/gem.naeblis.cx/gems"
  sh <<-end
    rsync -aP #{t.prerequisites.join ' '} gem.naeblis.cx:#{gem_path}/ && \
    ssh gem.naeblis.cx 'cd #{File.dirname(gem_path)} && ruby /usr/local/bin/index_gem_repository.rb -v'
  end
end

desc "Set the version in lib/date/performance.rb to #{NEXT_VERSION}"
task :bump do
  sh "sed 's/VERSION = .*/VERSION = \"#{NEXT_VERSION}\"/' lib/date/performance.rb > .performance.rb"
  mv ".performance.rb", "lib/date/performance.rb"
end

desc "Install using Ruby Gems"
task :install do
  sh "rake package"
  sh "sudo gem install pkg/#{PACKAGE_NAME}-#{VERS}"
end

desc "Uninstall using Ruby Gems"
task :uninstall => [:clean] do
  sh "sudo gem uninstall #{NAME}"
end

# Misc / Temporary ================================================================================

desc 'Measures test coverage'
task :coverage do |t|
  rm_f  "coverage"
  rm_f  "coverage.data"
  file_list = FileList.new("test/unit/*.rb")
  sh "RUBYLIB=test:lib rcov -i 'flat_file(/.+)?.rb' -T --sort coverage #{file_list.to_s}"
end


# Extension =======================================================================================

DLEXT = Config::CONFIG['DLEXT']
EXTENSION = "date_performance"
EXTENSION_DIR = "ext"
EXTENSION_SO = "#{EXTENSION_DIR}/#{EXTENSION}.#{DLEXT}"

directory "lib"

desc "Build the extension"
task EXTENSION => [ "lib/#{File.basename(EXTENSION_SO)}" ]

file "#{EXTENSION_DIR}/Makefile" => FileList[ "#{EXTENSION_DIR}/*.{c,h,rb}" ] do
  Dir.chdir(EXTENSION_DIR) { ruby "extconf.rb" }
end

file EXTENSION_SO => FileList[ "#{EXTENSION_DIR}/*.c", "#{EXTENSION_DIR}/Makefile" ] do |f|
  Dir.chdir(EXTENSION_DIR) { sh "make" }
end

file "lib/#{File.basename(EXTENSION_SO)}" => [ EXTENSION_SO ] do |t|
  cp EXTENSION_SO, t.name
end

desc "Compiles all extensions"
task :compile => [ "lib/#{File.basename(EXTENSION_SO)}" ]

# Tags ============================================================================================

# Generates ctags file
task :ctags do
  sh(<<-end, :verbose => false)
    ctags --recurse -f tags --extra=+f --links=yes --tag-relative=yes --totals=yes \
          --regex-ruby='/.*alias(_method)?[[:space:]]+:([[:alnum:]_=!?]+),?[[:space:]]+:([[:alnum:]_=!]+)/\\2/f/'
  end
end

# Generates ftags file for <Command+T> in Vim
task :ftags do |task|
  pattern = '.*(Rakefile|\.(rb|rhtml|rtxt|conf|c|h|ya?ml))'
  puts "building file tags (.#{task.name})"
  sh(<<-end, :verbose => false)
    find -regex '#{pattern.gsub(/[()|]/){|m| '\\' + m}}' -type f -printf "%f\t%p\t1\n" \
      | sort -f > .#{task.name}
  end
  sh "wc -l .#{task.name}", :verbose => false
end

desc "Generate ctags and ftags files"
task :tags => [ :ctags, :ftags ]
