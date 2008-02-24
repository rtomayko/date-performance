# An Intelligent Ruby Project Template
# 
# === Synopsis
#
# This file should be loaded at the top of your project Rakefile as follows:
# 
#   load "misc/project.rake"
#
#   Project.new "Test Project", "1.0" do |p|
#     p.package_name = 'test-project'
#     p.author = 'John Doe <jdoe@example.com>'
#     p.summary = 'A Project That Does Nothing'
#     p.description = <<-end
#       This project does nothing other than serve as an example of 
#       how to use this default project thingy. By the way, any leading
#       space included in this description is automatically stripped.
#
#       Even when text spans multiple paragraphs.
#     end
#
#     p.depends_on 'some-package', '~> 1.0'
#     p.remote_dist_location = "example.com:/dist/#{p.package_name}"
#     p.remote_doc_location = "example.com:/doc/#{p.package_name}"
#   end
# 
# A default set of Rake tasks are created based on the attributes specified.
# See the documentation for the Project class for more information.
#
# === MIT License
#
# Copyright (C) 2007 by Ryan Tomayko
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#  
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'

# The Project class stores various aspects of project configuration information
# and attempts to make best-guess assumptions about the current environment.
class Project

  # Array of project attribute names.
  @project_attributes = []

  class << self #:nodoc:

    # The first Project instance that's created is stored here. Messages sent
    # to the Project class are delegated here.
    attr_accessor :current

    # An array of attribute names available on project objects.
    attr_reader :project_attributes

    # Project class delegates missing messages to the current instance so let
    # the world know.
    def respond_to?(name, include_private=false) #:nodoc:
      super || (current && current.respond_to?(name, include_private))
    end

  private

    # Pass messages over to the current Project instance if we don't have an
    # implementation.
    def method_missing(name, *args, &b)
      if current && current.respond_to?(name)
        current.send(name, *args, &b)
      else
        super
      end
    end

    # An attr_writer that, when given a String, creates a FileList with the
    # given value.
    def file_list_attr_writer(*names)
      names.each do |name|
        class_eval <<-end_ruby
          undef #{name}=
          def #{name}=(value) 
            value = FileList[value.to_str] if value.respond_to?(:to_str)
            @#{name} = value
          end
        end_ruby
      end
    end

    # Track attributes as they're declares with attr_accessor.
    def attr_accessor_with_tracking(*names) #:nodoc:
      project_attributes.concat names
      attr_accessor_without_tracking(*names)
    end

  public

    send :alias_method, :attr_accessor_without_tracking, :attr_accessor
    send :alias_method, :attr_accessor, :attr_accessor_with_tracking

  end


  # The project's name. This should be short but may include spaces and
  # puncuation.
  attr_accessor :name

  alias :project_name :name

  # The package name that should be used when building distributables or when a
  # UNIX friendly name is otherwise needed. If this variable is not set, an
  # attempt is made to derive it from the +name+ attribute.
  attr_accessor :package_name

  # The project version as a string. This is typically read from a source 
  # file.
  attr_accessor :version

  # The source file that's used to keep the project version. The file will
  # typically include a +VERSION+ constant. With no explicit #version set,
  # this file will be inspected.
  #
  # The #version_pattern attribute can be used to describe how to locate the
  # version.
  attr_accessor :version_file

  # A string pattern that describes how the #version can be established from
  # the #version_file. The default pattern is 
  # <code>/^\s*VERSION\s*=\s*['"]([\.\d]+)['"]/</code>
  attr_accessor :version_pattern

  # A short, one/two sentence, description of the project.
  attr_accessor :summary

  # A longer -- single paragraph -- description of the project.
  attr_accessor :description

  # The directory where programs live. This is detected automatically if a 
  # +bin+ or +scripts+ directory exists off the project root.
  attr_accessor :bin_dir

  # A list of programs (under bin_dir) to install. This is detected
  # automatically.
  attr_accessor :programs

  # The directory where tests live. Default is +tests+.
  attr_accessor :test_dir

  # By default, this attribute returns a FileList of all test files living 
  # under +test_dir+ that match +test_pattern+ but can be set explicitly if
  # needed.
  attr_accessor :tests

  # A glob string used to find test cases. Default: '**/*_test.rb'
  attr_accessor :test_pattern

  # Directory where library files. Default: +lib+
  attr_accessor :lib_dir

  # A FileList of library files. Defaults to all .rb files under +lib_dir+
  attr_accessor :lib_files

  # The top-level documentation directory. Default: +doc+.
  attr_accessor :doc_dir

  # All documentation files. Default is to include everything under +doc_dir+
  # except for API documentation.
  attr_accessor :doc_files

  # Additional files to include in generated API documentation
  attr_accessor :rdoc_files

  # The author's name and email address: "Mr Foo <foo@example.com>"
  attr_accessor :author

  # The author's name. If this is not set, an attempt is made to establish it
  # from the +author+ attribute.
  attr_accessor :author_name

  # The author's email. If this is not set, an attempt is made to establish it
  # from the +author+ attribute.
  attr_accessor :author_email

  # The project's homepage URL.
  attr_accessor :project_url

  # Directory where distributables are built.
  attr_accessor :package_dir

  # Any additional files to include in the package.
  attr_accessor :extra_files

  # Native extension files. Default: <tt>FileList['ext/**/*.{c,h,rb}']</tt>.
  attr_accessor :extension_files

  # An Array of gem dependencies. The #depends_on is the simplest way of getting
  # new dependencies defined.
  attr_accessor :dependencies

  # A remote location where packages should published. This should be of the
  # form host.domain:/path/to/dir
  attr_accessor :remote_dist_location

  # The shell command to run on the remote dist host that reindexes the gem
  # repository. This is typically something like 
  # <code>'cd ~/www/gems && index_gem_repository.rb -v'</code>. If you don't
  # maintain a gem repository, this is safe to ignore.
  attr_accessor :index_gem_repository_command #:nodoc:

  # The remote location where built documentation should be published. This
  # should be of the form host.domain:/path/to/dir
  attr_accessor :remote_doc_location

  # The remote location where the git repo should be published. This should
  # be of the form host.domain:/path/to/dir.git The local .git directory is copied 
  # to the destination directly.
  attr_accessor :remote_branch_location

  # Generate README file based on project information.
  attr_accessor :generate_readme

  file_list_attr_writer :tests, :lib_files, :doc_files, :extra_files, :rdoc_files,
    :extension_files

  def initialize(project_name, options={}, &b)
    self.class.current ||= self
    @name = project_name
    @version = options.delete(:version)
    @version_file = nil
    @version_pattern = /^\s*VERSION\s*=\s*['"]([\.\d]+)['"]/
    @summary, @description, @package_name = nil
    @author, @author_email, @author_name = nil
    @bin_dir, @programs = nil
    @test_dir, @tests = nil
    @test_pattern = 'test/**/*_test.rb'
    @lib_dir = 'lib'
    @lib_files = nil
    @doc_dir = 'doc'
    @doc_files = nil
    @rdoc_dir = nil
    @rdoc_files = Rake::FileList['{README,LICENSE,COPYING}*']
    @package_dir = 'dist'
    @extra_files = Rake::FileList['Rakefile', 'Change{Log,s}*', 'NEWS*', 'misc/*.rake']
    @extension_files = nil
    @project_url = nil
    @dependencies = []
    @remote_dist_location, @remote_doc_location, @remote_branch_location = nil
    @index_gem_repository_command = nil
    @generate_readme = false
    @package_configurator = nil
    @rdoc_configurator = nil
    @test_configurator = nil
    enhance(options, &b)
    define_tasks
  end

  def enhance(options={})
    options.each { |k,v| send("#{k}=", v) }
    yield self if block_given?
  end

  undef :package_name, :description=, :bin_dir, :test_dir, :programs, :tests, 
    :lib_files, :doc_files

  def package_name #:nodoc:
    read_attr(:package_name) { name.downcase.gsub(/[:\s]+/, '-') }
  end

  undef version

  def version #:nodoc:
    read_attr(:version, true) { read_version_from_version_file }
  end

  # Read the version from version_file using the version_pattern.
  def read_version_from_version_file #:nodoc:
    if version_file
      if match = File.read(version_file).match(version_pattern)
        match[1]
      else
        fail "No version match %p in %p." % [ version_file, version_pattern ]
      end
    else
      fail "No version or version_file specified."
    end
  end

  # Writes the currently set version to the version file.
  def update_version_and_write_to_version_file(version) #:nodoc:
    contents = File.read(version_file)
    if match = contents.match(version_pattern)
      old_version_line = match[0]
      new_version_line = old_version_line.sub(match[1], version)
      contents.sub! old_version_line, new_version_line
      File.open(version_file, 'wb') { |io| io.write(contents) }
    else
      fail "Project version not found in #{version_file} (pattern: %p)." % version_pattern
    end
  end

  # The next version, calculated by incrementing the last version component by
  # 1. For instance, the version after +0.2.9+ is +0.2.10+.
  def next_version #:nodoc:
    parts = version.split('.')
    parts[-1] = (parts[-1].to_i + 1).to_s
    parts.join('.')
  end

  def description=(value) #:nodoc:
    @description =
      if value.respond_to? :to_str
        value.to_str.strip_leading_indentation.strip
      else
        value
      end
  end

  def bin_dir #:nodoc:
    read_attr(:bin_dir) { FileList['bin', 'scripts'].existing.first }
  end

  def test_dir #:nodoc:
    read_attr(:test_dir) { FileList['test'].existing.first }
  end

  def programs #:nodoc:
    read_attr(:programs, true) { bin_dir ? FileList["#{bin_dir}/*"] : [] }
  end

  def tests #:nodoc:
    read_attr(:tests, true) { test_dir ? FileList[test_pattern] : [] }
  end

  def lib_files #:nodoc:
    read_attr(:lib_files, true) { FileList["#{lib_dir}/**/*.rb"] }
  end

  def doc_files #:nodoc:
    read_attr(:doc_files) { 
      FileList["doc/**/*"] - FileList["#{rdoc_dir}/**/*", rdoc_dir] }
  end

  def rdoc_dir #:nodoc:
    read_attr(:rdoc_dir) { File.join(doc_dir, 'api') }
  end

  def extensions_dir
    'ext'
  end

  undef extension_files

  def extension_files
    read_attr(:extension_files) { FileList["#{extensions_dir}/**/*.{h,c,rb}"] }
  end

  undef author

  def author #:nodoc:
    read_attr(:author, true) { 
      if @author_name && @author_email
        "#{@author_name} <#{@author_email}>"
      elsif @author_name
        @author_name
      elsif @author_email
        @author_email
      end
    }
  end

  undef :author_name

  def author_name #:nodoc:
    read_attr(:author_name) { author && author[/[^<]*/].strip }
  end

  undef :author_email

  def author_email #:nodoc:
    read_attr(:author_email) { 
      if author && author =~ /<(.*)>$/
        $1
      else
        nil
      end
    }
  end

  # All files to be included in built packages. This includes +lib_files+,
  # +tests+, +rdoc_files+, +programs+, and +extra_files+.
  def package_files
    (rdoc_files + lib_files + tests + doc_files + 
     programs + extra_files + extension_files).uniq
  end

  # The basename of the current distributable package.
  def package_basename(extension='.gem')
    [ package_name, version ].join('-') + extension
  end

  # The path from the project root to a package distributable.
  def package_path(extension='.gem')
    File.join(package_dir, package_basename(extension))
  end

  # A list of built package distributables for the current project version.
  def packages
    FileList[package_path('.*')]
  end

  # Declare that this project depends on the specified package.
  def depends_on(package, *version)
    dependencies << [ package, *version ]
  end

  def configure_package(&block)
    @package_configurator = block
  end

  def configure_rdoc(&block)
    @rdoc_configurator = block
  end

  def configure_tests(&block)
    @test_configurator = block
  end

public

  # An Array of attribute names available for the project.
  def project_attribute_array
    self.class.project_attributes.collect do |name|
      [ name.to_sym, send(name) ]
    end
  end

  alias :to_a :project_attribute_array

  # A Hash of attribute name to attribute values -- one for each project 
  # attribute.
  def project_attribute_hash
    to_a.inject({}) { |hash,(k,v)| hash[k] = v }
  end

  alias :to_hash :project_attribute_hash

public

  # A Gem::Specification instance with values based on the attributes defined on
  # the project
  def gem_spec
    Gem::Specification.new do |s|
      s.name = package_name
      s.version = version
      s.platform = Gem::Platform::RUBY
      s.summary = summary
      s.description = description || summary
      s.author = author_name
      s.email = author_email
      s.homepage = project_url
      s.require_path = lib_dir
      s.files = package_files
      s.test_files = tests
      s.bindir = bin_dir
      s.executables = programs.map{|p| File.basename(p)}
      s.extensions = FileList['ext/**/extconf.rb']
      s.has_rdoc = true
      s.extra_rdoc_files = rdoc_files
      s.rdoc_options.concat(rdoc_options)
      s.test_files = tests
      dependencies.each { |args| s.add_dependency(*args) }
      @package_configurator.call(s) if @package_configurator
    end
  end

private

  # Read and return the instance variable with name if it is defined and is non
  # nil. When the variable's value is a Proc, invoke it and return the
  # result. When the variable's value is nil, yield to the block and return the
  # result.
  def read_attr(name, record=false)
    result =
      case value = instance_variable_get("@#{name}")
      when nil
        yield if block_given?
      when Proc
        value.to_proc.call(self)
      else
        value
      end
    instance_variable_set("@#{name}", result) if record
    result
  end

  # Define Rake tasks for this project.
  def define_tasks
    private_methods.grep(/^define_(\w+)_tasks$/).each do |meth| 
      namespace_name = meth.match(/^define_(\w+)_tasks$/)[1]
      send(meth)
    end
  end

  # Project Tasks ===========================================================

  def define_project_tasks
    namespace :project do
      desc "Show high level project information"
      task :info do |t|
        puts [ project_name, version ].compact.join('/')
        puts summary if summary
        puts "\n%s" % [ description ] if description
      end

      desc "Write project version to STDOUT"
      task :version do |t|
        puts version
      end

      if version_file
        bump_version_to = ENV['VERSION'] || next_version
        desc "Bump project version (to %s) in %s" % [ bump_version_to, version_file ]
        task :revise => [ version_file ] do |t|
          message = "bumping version to %s in %s" % [ bump_version_to, version_file ]
          STDERR.puts message if verbose
          update_version_and_write_to_version_file(bump_version_to)
        end
      else
        task :bump
      end

      desc "Write project / package attributes to STDOUT"
      task :attributes do |t|
        puts project_attribute_array.collect { |k,v| "%s: %p" % [ k, v ] }.join("\n")
      end
    end
  end

  # Test Tasks ===============================================================

  def define_test_tasks
    desc "Run all tests under #{test_dir}"
    Rake::TestTask.new :test do |t|
      t.libs = [ lib_dir, test_dir ]
      t.ruby_opts = [ '-rubygems' ]
      t.warning = true
      t.test_files = tests
      t.verbose = false
      @test_configurator.call(t) if @test_configurator
    end
  end

  # Package Tasks ===========================================================

  def define_package_tasks
    @package_config =
      Rake::GemPackageTask.new(gem_spec) do |p|
        p.package_dir = package_dir
        p.need_tar_gz = true
        p.need_zip = true
      end
    
    Rake::Task[:package].comment = nil
    Rake::Task[:repackage].comment = nil
    Rake::Task[:clobber_package].comment = nil
    Rake::Task[:gem].comment = nil

    namespace :package do
      desc "Build distributable packages under #{package_dir}"
      task :build => :package

      desc "Rebuild distributable packages..."
      task :rebuild => :repackage

      desc "Remove most recent package files"
      task :clean => :clobber_package

      desc "Dump package manifest to STDOUT"
      task :manifest do |t|
        puts package_files.sort.join("\n")
      end

      desc "Install #{package_basename} (requires sudo)"
      task :install => package_path do |t|
        sh "sudo gem install #{package_path}"
      end

      desc "Uninstall #{package_basename} (requires sudo)"
      task :uninstall do |t|
        sh "sudo gem uninstall #{package_name} --version #{version}"
      end
    end
  end

  # Doc Tasks ===============================================================

  def define_doc_tasks
    desc "Remove all generated documentation"
    task 'doc:clean'

    desc "Build all documentation under #{doc_dir}"
    task 'doc:build'

    desc "Rebuild all documentation ..."
    task 'doc:rebuild'

    task :clean => 'doc:clean'
    task :build => 'doc:build'
    task :rebuild => 'doc:rebuild'
    task :doc => 'doc:build'
  end

  def rdoc_options
    [ 
      "--title", "#{project_name} API Documentation",
      '--extension', 'rake=rb', 
      '--line-numbers',
      '--inline-source',
      '--tab-width=4'
    ]
  end

  def define_rdoc_tasks
    namespace :doc do
      Rake::RDocTask.new do |r|
        r.rdoc_dir = rdoc_dir
        r.main = project_name if project_name =~ /::/
        r.title = "#{project_name} API Documentation"
        r.rdoc_files.add lib_files
        r.options = rdoc_options
      end
    end

    Rake::Task['doc:rdoc'].comment = nil
    Rake::Task['doc:rerdoc'].comment = nil
    Rake::Task['doc:clobber_rdoc'].comment = nil

    task 'doc:api:rebuild' => 'doc:rerdoc'
    task 'doc:api:clean'   => 'doc:clobber_rdoc'

    desc "Build API / RDoc under #{rdoc_dir}" 
    task 'doc:api' => 'doc:rdoc'

    task 'doc:clean' => 'doc:api:clean'
    task 'doc:build' => 'doc:api'
    task 'doc:rebuild' => 'doc:api:rebuild'
  end

  # AsciiDoc Tasks ==========================================================

  def asciidoc_available?
    @asciidoc_available ||=
      system 'asciidoc --version > /dev/null 2>&1'
  end

  # Attributes passed to asciidoc for use in documents.
  def asciidoc_attributes
    { 'author'                => author_name,
      'email'                 => author_email,
      'project-name'          => project_name,
      'package-name'          => package_name,
      'package-version'       => version,
      'package-description'   => description,
      'package-summary'       => summary,
      'project-url'           => project_url 
    }.reject{|k,v| v.nil? }
  end

  # Defines tasks for building HTML documentation with AsciiDoc.
  def define_asciidoc_tasks
    if defined?(AsciiDocTasks) && File.exist?("#{doc_dir}/asciidoc.conf") && asciidoc_available?
      man_pages = FileList["#{doc_dir}/*.[0-9].txt"]
      articles = FileList["#{doc_dir}/*.txt"] - man_pages
      desc "Build AsciiDoc under #{doc_dir}"
      AsciiDocTasks.new('doc:asciidoc') do |t|
        t.source_dir = doc_dir
        t.source_files = articles
        t.doc_type = :article
        t.config_file = "#{doc_dir}/asciidoc.conf"
        t.attributes = asciidoc_attributes
      end
      AsciiDocTasks.new('doc:asciidoc') do |t|
        t.source_dir = doc_dir
        t.source_files = man_pages
        t.doc_type = :manpage
        t.config_file = "#{doc_dir}/asciidoc.conf"
        t.attributes = asciidoc_attributes
      end
    else
      desc "Build AsciiDoc (disabled)"
      task 'asciidoc'
      task 'asciidoc:build'
      task 'asciidoc:clean'
      task 'asciidoc:rebuild'
    end
    task 'doc:build' => 'doc:asciidoc:build'
    task 'doc:clean' => 'doc:asciidoc:clean'
    task 'doc:rebuild' => 'doc:asciidoc:rebuild'
  end


  # Publishing ==============================================================

  class RemoteLocation #:nodoc:
    attr_reader :user, :host, :path
    def initialize(location)
      if location =~ /^([\w\.]+):(.+)$/
        @user, @host, @path = ENV['USER'], $1, $2
      elsif location =~ /^(\w+)@([\w\.]+):(.+)$/
        @user, @host, @path = $1, $2, $3
      else
        raise ArgumentError, "Invalid remote location: %p" % location
      end
    end
    def to_s
      "#{user}@#{host}:#{path}"
    end
    def inspect
      to_s.inspect
    end
    def self.[](location)
      if location.respond_to?(:to_str)
        new(location.to_str)
      else
        location
      end
    end
  end

public

  undef :remote_dist_location=

  def remote_dist_location=(value) #:nodoc:
    @remote_dist_location = RemoteLocation[value]
  end

  undef :remote_doc_location=

  def remote_doc_location=(value) #:nodoc:
    @remote_doc_location = RemoteLocation[value]
  end

  undef :remote_branch_location=

  def remote_branch_location=(value) #:nodoc:
    @remote_branch_location = RemoteLocation[value]
  end

private

  def remote_index_gem_repository_command #:nodoc:
    if index_gem_repository_command
      "ssh #{remote_dist_location.user}@#{remote_dist_location.host}" +
      "'#{index_gem_repository_command}'"
    end
  end

  def rsync_packages_command #:nodoc:
    "rsync -aP #{packages.join(' ')} #{remote_dist_location}"
  end

  def publish_packages_command #:nodoc:
    [ rsync_packages_command, remote_index_gem_repository_command ].compact.join(' && ')
  end

  def publish_doc_command
    "rsync -azP #{doc_dir}/ #{remote_doc_location}"
  end
  
  def temporary_git_repo_dir
    ".git-#{Process.pid}"
  end

  def publish_branch_command
  [ 
    "git repack -d",
    "git clone --bare -l . #{temporary_git_repo_dir}",
    "git --bare --git-dir=#{temporary_git_repo_dir} update-server-info",
    "rsync -azP --delete --hard-links #{temporary_git_repo_dir}/ #{remote_branch_location}" 
  ].join(' && ')
  end

  def define_publish_tasks
    desc 'Publish'
    task 'publish'

    if remote_dist_location
      desc "Publish packages to #{remote_dist_location}"
      task 'publish:packages' => 'package:build' do |t|
        sh publish_packages_command, :verbose => true
      end
      desc 'packages'
      task 'publish' => 'publish:packages'
    end

    if remote_branch_location && File.exist?('.git')
      desc "Publish branch to #{remote_branch_location}"
      task 'publish:branch' => '.git' do |t|
        sh publish_branch_command, :verbose => true do |res,ok|
          rm_rf temporary_git_repo_dir
          fail "publish git repository failed." if ! ok
        end
      end
      desc 'branch'
      task 'publish' => 'publish:branch'
    end

    if remote_doc_location
      desc "Publish doc to #{remote_doc_location}"
      task 'publish:doc' => 'doc:build' do |t|
        sh publish_doc_command, :verbose => true
      end
      desc 'doc'
      task 'publish' => 'publish:doc'
    end

  end

  # Tags ====================================================================
  
  def define_tags_tasks

    task :ctags => (lib_files + tests) do |t|
      args = [
        "--recurse",
        "-f tags",
        "--extra=+f",
        "--links=yes",
        "--tag-relative=yes",
        "--totals=yes",
        "--regex-ruby='/.*alias(_method)?[[:space:]]+:([[:alnum:]_=!?]+),?[[:space:]]+:([[:alnum:]_=!]+)/\\2/f/'"
      ].join(' ')
      sh 'ctags', *args
    end

    CLEAN.include [ 'tags' ]

    task :ftags => FileList['Rakefile', '**/*.{r*,conf,c,h,ya?ml}'] do |t|
      pattern = '.*(Rakefile|\.(rb|rhtml|rtxt|conf|c|h|ya?ml))'
      command = [
        "find",
        "-regex '#{pattern.gsub(/[()|]/){|m| '\\' + m}}'",
        "-type f",
        "-printf '%f\t%p\t1\n'",
        "| sort -f > #{t.name}"
      ].join(' ')
      sh command
    end
  
    CLEAN.include [ '.ftags' ]

    desc "Generate tags file with ctags"
    task :tags => [ :ctags, :ftags ]
  end

end

class String

  # The number of characters of leading indent. The line with the least amount
  # of indent wins:
  #
  #   text = <<-end
  #     this is line 1
  #       this is line 2
  #       this is line 3
  #     this is line 4
  #   end
  #   assert 2 == text.leading_indent
  # 
  # This is used by the #strip_leading_indent method.
  def leading_indentation_length
    infinity = 1.0 / 0.0
    inject infinity do |indent,line|
      case line
      when /^[^\s]/
        # return immediately on first non-indented line
        return 0
      when /^\s+$/
        # ignore lines that are all whitespace
        next indent
      else
        this = line[/^[\t ]+/].length
        this < indent ? this : indent
      end
    end
  end

  # Removes the same amount of leading space from each line in the string. The
  # number of spaces removed is based on the #leading_indent_length. 
  #
  # This is most useful for reformatting inline strings created with here docs.
  def strip_leading_indentation
    if (indent = leading_indentation_length) > 0
      collect { |line| line =~ /^[\s]+[^\s]/ ? line[indent..-1] : line }.join
    else
      self
    end
  end

end
