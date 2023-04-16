module TasksWeb::Controllers::Public
  before_all "/login" do |env|
    env.redirect "/dashboard" if env.get?(Auth::CONTEXT_USER)
  end

  get "/login" do
    render_html "public/login"
  end

  post "/login" do |env|
    email = env.params.body["email"]?
    password = env.params.body["password"]?

    if !email || email.empty? || !password || password.empty?
      halt env, status_code: 400, response: "Email and password mandatory"
    end

    # Testing to set cookie
    Auth::LoginService.call env, email

    env.redirect "/"
  end
end
