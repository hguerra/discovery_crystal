class HomeController < ApplicationController
  get "/", &method(:index)
  get "/about/:name", &method(:about)

  def index
    # page(Home::IndexView, feed_items)
    html "home/index"
  end

  def about
    name = params.url["name"]
    user = User.new 1, name
    AboutUser.call user
  end
end
