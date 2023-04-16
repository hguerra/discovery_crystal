module TasksWeb::Controllers::Public
  before_all "/" do |env|
    env.redirect "/dashboard" if env.get?(Auth::CONTEXT_USER)
  end

  get "/" do
    render_template "public/home"
  end
end
