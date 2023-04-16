module TasksWeb::Controllers::Dashboard
  get "/dashboard" do |env|
    user = env.get(Auth::CONTEXT_USER).as(Auth::User)
    name = user.claims.subject
    render_template "dashboard/index"
  end
end
