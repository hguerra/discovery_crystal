require "./application_service"

class AboutUser < ApplicationService
  def initialize(@user : User)
  end

  def call
    "about user name: #{@user.name}"
  end
end
