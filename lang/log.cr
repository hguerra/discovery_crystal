require "log"
require "json"

Log.info { "Program started" }
Log.info &.emit("User logged in", user_id: 42)

# struct MyFormat < Log::StaticFormatter
#   def run
#     string "- "
#     severity
#     string ": "
#     message
#   end
# end

# Log.define_formatter MyFormat, "#{timestamp} #{severity} - #{source(after: ": ")}#{message} #{data(before: " -- ")}#{context(before: " -- ")}#{exception}"

# https://cloud.google.com/logging/docs/structured-logging?hl=pt-br
# https://cloud.google.com/logging/docs/reference/v2/rest/v2/LogEntry#LogSeverity
# Log.define_formatter GoogleLogFormat, %({"time":"#{timestamp}","severity":"#{severity}","message":"#{source(after: ": ")}#{message} #{data(before: " -- ")}#{context(before: " -- ")}#{exception}")

struct GoogleLogFormat < Log::StaticFormatter
  def custom_timestamp
    @entry.timestamp.to_rfc3339
  end

  def custom_severity
    case @entry.severity
    in Log::Severity::Trace  then "DEFAULT"
    in Log::Severity::Debug  then "DEBUG"
    in Log::Severity::Info   then "INFO"
    in Log::Severity::Notice then "NOTICE"
    in Log::Severity::Warn   then "WARNING"
    in Log::Severity::Error  then "ERROR"
    in Log::Severity::Fatal  then "EMERGENCY"
    in Log::Severity::None   then "DEBUG"
    end
  end

  def custom_message
    message = @entry.message

    if @entry.source.size > 0
      message = "#{@entry.source}: #{message}"
    end

    if ex = @entry.exception
      message = "#{message}\n#{ex.inspect_with_backtrace}"
    end

    message
  end

  def custom_labels
    unless @entry.data.empty?
      labels = Hash(String, String).new
      @entry.data.each do |(k, v)|
        labels[k.to_s] = v.to_s
      end
      labels
    end
  end

  def custom_operations
    unless @entry.context.empty?
      operations = Hash(String, String).new
      @entry.context.each do |(k, v)|
        operations[k.to_s] = v.to_s
      end
      operations
    end
  end

  def custom_span_id
    unless @entry.data.empty?
      value = @entry.data[:span_id]?
      if value
        return value.to_s
      end
    end
  end

  def custom_trace
    unless @entry.data.empty?
      value = @entry.data[:trace]?
      if value
        return value.to_s
      end
    end
  end

  def to_json
    {
      "time"                             => custom_timestamp,
      "severity"                         => custom_severity,
      "message"                          => custom_message,
      "logging.googleapis.com/labels"    => custom_labels,
      "logging.googleapis.com/operation" => custom_operations,
      "logging.googleapis.com/spanId"    => custom_span_id,
      "logging.googleapis.com/trace"     => custom_trace,
    }.to_json
  end

  def run
    string to_json
  end
end

Log.setup do |c|
  backend = Log::IOBackend.new(formatter: GoogleLogFormat)

  c.bind "*", :debug, backend
end

module DB
  # Log = ::Log.for("db") # Log for db source
  Log = ::Log.for(self) # Log for db source

  def do_something
    Log.info { "this is logged in db source" }
  end
end

DB::Log.info { "this is also logged in db source" }
Log.for("db").info { "this is also logged in db source" }
Log.for("db").info &.emit("User logged in", user_id: 42)
Log.for("db").error &.emit("User logged in", user_id: 42)
Log.for("db").warn &.emit("User logged in", user_id: 42, other: "abc")

begin
  Log.context.set id: "get_data"
  Log.context.set producer: "github.com/MyProject/MyApplication"
  raise Exception.new("Some error")
rescue e
  Log.error exception: e, &.emit("Oh no!", user_id: 42, span_id: "000000000000004a", trace: "projects/my-projectid/traces/06796866738c859f2f19b7cfb3214824")
end
