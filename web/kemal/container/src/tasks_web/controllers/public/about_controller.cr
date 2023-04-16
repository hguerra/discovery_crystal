module TasksWeb::Controller::Public
  get "/about" do
    render_template "public/about"
  end
end
