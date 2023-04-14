module MyApp
  module Configuration
    CLI_PATH = "/usr/bin"
    FAIL_FAST = true

    def self.configure(&block)
      yield self
    end
  end

  module Utilities
    # Yields temp file with given dot-based extension
    def self.tempfile(ext : String)
      ::File.tempfile("myfile", ext) do |file|
        yield file
      end
    end

    def self.tempfile(ext)
      ::File.tempfile("myfile", ext)
    end
  end

  class Error < Exception
  end

  class Invalid < Error
  end

  class Shell
    def run(command, options : Hash(Symbol, Bool | String) = {} of Symbol => Bool | String)
      whiny = options.has_key?(:fail_fast) ? options[:fail_fast] : Configuration::FAIL_FAST
      stdout, stderr, status = execute(command)
      if status != 0 && whiny
        raise Error.new("`#{command.join(" ")}` failed with error(#{status}):\n#{stderr}\noutput:\n#{stdout}")
      end
      {stdout, stderr, status}
    end

    def execute(command : Array(String))
      output = IO::Memory.new
      error = IO::Memory.new
      command[1..-1].each_with_index do |e, i|
        j = i + 1
        command[j] = "'#{e}'" if e.includes?(' ')
      end
      puts command.join(" ")
      res = Process.run(command.join(" "), shell: true, output: output, error: error)
      {output, error, res.exit_status}
    end
  end

  class Tool
    def initialize(@name : String)
      @args = [] of String
      @fail_fast = Configuration::FAIL_FAST
    end

    def <<(arg : String)
      @args << arg.to_s
      self
    end

    def send(name : String)
      @args << "-#{name}"
      self
    end

    def command
      arr = [] of String
      arr.concat(executable)
      arr.concat(@args)
      arr
    end

    def executable
      exe = [@name]
      exe.unshift File.join(Configuration::CLI_PATH, exe.shift) unless Configuration::CLI_PATH.empty?
      exe
    end

    def call : String
      shell = Shell.new
      stdout = shell.run(command, {:fail_fast => @fail_fast})[0]
      stdout.to_s.strip
    end

    def call(&block)
      shell = Shell.new
      stdout, stderr, status = shell.run(command, {:fail_fast => @fail_fast})
      yield stdout, stderr, status
      stdout.to_s.strip
    end
  end
end

tool = MyApp::Tool.new "ls"
puts tool.send("lah").call
