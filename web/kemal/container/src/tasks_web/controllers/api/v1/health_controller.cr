module TasksWeb::Controllers::Api::V1
  get "/api/v1/health" do
    {"status": "UP"}.to_json
  end
end
