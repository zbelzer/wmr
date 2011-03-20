require 'trollop'

module WMR
  class Daemon
    class << self
      def run
        opts = parse_options
        register_signal_handlers
        daemonize if opts[:daemon]
        pidfile opts[:pidfile]
        redirect opts
        start
      end

      def parse_options
        opts = Trollop::options do
          version File.read(File.expand_path('../../../VERSION', __FILE__))
          opt :config, "Alternate path to config file",                 :short => "-c"
          opt :daemon, "Run as a background daemon", :default => false, :short => "-d"
          opt :stdout, "Redirect stdout to logfile", :type => String,   :short => '-o'
          opt :stderr, "Redirect stderr to logfile", :type => String,   :short => '-e'
          opt :nosync, "Don't sync logfiles on every write"
          opt :pidfile, "PID file location",         :type => String,   :short => "-p"
        end
        if opts[:daemon]
          opts[:stdout]  ||= "log/wmr.stdout.log"
          opts[:stderr]  ||= "log/wmr.stderr.log"
          opts[:pidfile] ||= "tmp/pids/wmr.pid"
        end
        opts
      end

      def daemonize
        raise 'First fork failed' if (pid = fork) == -1
        exit unless pid.nil?
        Process.setsid
        raise 'Second fork failed' if (pid = fork) == -1
        exit unless pid.nil?
      end

      def pidfile(pidfile)
        pid = Process.pid
        if pidfile
          if File.exist? pidfile
            raise "Pidfile already exists at #{pidfile}.  Check to make sure process is not already running."
          end
          File.open pidfile, "w" do |f|
            f.write pid
          end
          at_exit do
            if Process.pid == pid
              File.delete pidfile
            end
          end
        end
      end

      def redirect(opts)
        $stdin.reopen  '/dev/null'        if opts[:daemon]
        $stdout.reopen opts[:stdout], "a" if opts[:stdout] && !opts[:stdout].empty?
        $stderr.reopen opts[:stderr], "a" if opts[:stderr] && !opts[:stderr].empty?
        $stdout.sync = $stderr.sync = true unless opts[:nosync]
      end

      def register_signal_handlers
        trap('TERM') { @running = false }
        trap('INT')  { @running = false }
      end

      def start
        @running = true

        wmr = Interface.new

        begin
          wmr.initialize!

          while @running do
            wmr.read_data do |type, data|
              if type == :unknown
                puts "Unknown packet type: #{type}, skipping"
              else
                puts "Processing #{type}"
                puts data.inspect
              end
            end
          end
        end
      rescue => e
        puts "Caught exception:"
        puts e.message
        # puts e.backtrace.join("\n")
      ensure
        wmr.cleanup
      end
    end

    def stop
      puts "Stopping WMR"
      @running = false
    end
  end
end
