
# Run asciidoc.
def asciidoc(source, dest, *args)
  options = args.last.is_a?(Hash) ? args.pop : {}
  options[:verbose] = verbose if options[:verbose].nil?
  attributes = options[:attributes] || {}
  config_file = options[:config_file]
  if source_dir = options[:source_dir]
    source = source.sub(/^#{source_dir}/, '.')
    dest = dest.sub(/^#{source_dir}/, '.')
    config_file = config_file.sub(/^#{source_dir}/, '.') if config_file
  end
  command = [
    'asciidoc',
    ('--unsafe' unless options[:safe]),
    ('--verbose' if options[:verbose]),
    ('--no-header-footer' if options[:suppress_header]),
    ("-a theme=#{options[:theme]}" if options[:theme]),
    ("-a stylesdir='#{options[:styles]}'" if options[:styles]),
    "-a linkcss -a quirks\!",
    ("-f '#{config_file}'" if config_file),
    attributes.map{|k,v| "-a #{k}=#{v.inspect}" },
    ("-d #{options[:doc_type]}" if options[:doc_type]),
    "-o", dest,
    args,
    source
  ].flatten.compact
  chdir(options[:source_dir] || Dir.getwd) { sh command.join(' ') }
end


class AsciiDocTasks
 
  attr_reader :task_name

  # The directory where asciidoc sources are stored. Defaults to +doc+.
  attr_accessor :source_dir

  # A list of source files to build.
  attr_accessor :source_files

  # Set true to disable potentially unsafe document instructions. For example,
  # the asciidoc sys:: macro is disabled when safe mode is enabled.
  attr_accessor :safe

  # Override the default verbosity.
  attr_accessor :verbose

  # Do not output header and footer.
  attr_accessor :suppress_header

  # An asciidoc configuration file.
  attr_accessor :config_file

  # One of :article, :manpage, or :book
  attr_accessor :doc_type

  # Hash of asciidoc attributes passed in via the -a argument.
  attr_accessor :attributes

  def initialize(task_name)
    @task_name = task_name
    @source_dir = 'doc'
    @source_files = FileList.new
    @safe = false
    @verbose = nil
    @suppress_header = false
    @doc_type = :article
    @config_file = nil
    yield self if block_given?
    define!
  end

  def define!
    task task_name => "#{task_name}:build"
    task "#{task_name}:clean"
    task "#{task_name}:build"
    task "#{task_name}:rebuild"
    task :clean => "#{task_name}:clean"
    source_and_destination_files.each do |source,dest|
      file dest => [ source, config_file ].compact do |f|
        asciidoc source, dest, options
      end
      task("#{task_name}:build" => dest)
      task("#{task_name}:clean") { rm_f dest }
      task("#{task_name}:rebuild" => [ "#{task_name}:clean", "#{task_name}:build" ])
    end
  end

private

  def destination_files
    source_files.collect { |path| path.sub(/\.\w+$/, ".html") }
  end

  def source_and_destination_files
    source_files.zip(destination_files)
  end

  def config_file
    @config_file || 
      if File.exist?("#{source_dir}/asciidoc.conf") 
        "#{source_dir}/asciidoc.conf"
      else
        nil
      end
  end

  def options
    { :safe => safe,
      :suppress_header => suppress_header,
      :verbose => self.verbose,
      :source_dir => source_dir,
      :config_file => config_file,
      :doc_type => doc_type,
      :attributes => attributes }
  end

end
