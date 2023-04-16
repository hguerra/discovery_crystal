abstract class ApplicationService
  def self.call(*args)
    new(*args).call
  end

  abstract def call
end
