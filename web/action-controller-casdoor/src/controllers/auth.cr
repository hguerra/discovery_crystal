require "./application"
require "../services/casdoor_client"

class App::Auth < App::Application
  base "/auth"

  # Mock data para simular usuários do Casdoor
  MOCK_USERS = {
    "admin" => {
      "id"           => "admin",
      "name"         => "admin",
      "displayName"  => "Administrator",
      "email"        => "admin@example.com",
      "avatar"       => "https://via.placeholder.com/150",
      "access_token" => "mock_admin_token_123",
    },
    "user1" => {
      "id"           => "user1",
      "name"         => "user1",
      "displayName"  => "John Doe",
      "email"        => "john@example.com",
      "avatar"       => "https://via.placeholder.com/150",
      "access_token" => "mock_user1_token_456",
    },
  }

  # Utilitário para salvar usuário na sessão
  private def save_user_session(id : String, name : String, email : String, _access_token : String, roles : Array(String)? = nil)
    session["user_id"] = id
    session["user_name"] = name
    session["user_email"] = email
    session["user_roles"] = roles.try(&.join(",")) || ""
    # Não salva access_token na sessão
  end

  # Utilitário para gerar URL completa do callback
  private def callback_url : String
    host = request.headers["Host"]? || "localhost:3000"
    protocol = request.headers["X-Forwarded-Proto"]? || "http"
    "#{protocol}://#{host}/auth/callback"
  end

  # Página inicial - pública
  @[AC::Route::GET("/")]
  def index
    render template: "auth/index.ecr"
  end

  # Redireciona para "login" (simulado)
  @[AC::Route::GET("/login")]
  def login(mock : String? = nil)
    if mock && (user = MOCK_USERS[mock]?)
      save_user_session(user["id"], user["displayName"], user["email"], "", [] of String)
      Log.info { "User logged in (mock): #{mock}" }
      redirect_to "/auth/dashboard"
    else
      # Redireciona para Casdoor real
      client = CasdoorClient.new
      redirect_uri = callback_url
      state = UUID.random.to_s
      url = client.build_authorization_url(redirect_uri, state)
      redirect_to url
    end
  end

  # Simula login com usuário específico
  @[AC::Route::GET("/login/:user_id")]
  def login_as(user_id : String)
    user = MOCK_USERS[user_id]?
    if user
      save_user_session(user["id"], user["displayName"], user["email"], "", [] of String)
      Log.info { "User logged in: #{user_id}" }
      redirect_to "/auth/dashboard"
    else
      Log.warn { "Invalid user login attempt: #{user_id}" }
      redirect_to "/auth/login"
    end
  end

  # Simula o callback OAuth do Casdoor
  @[AC::Route::GET("/callback")]
  def callback(
    @[AC::Param::Info(description: "Authorization code from Casdoor")]
    code : String? = nil,
    @[AC::Param::Info(description: "State parameter for CSRF protection")]
    state : String? = nil,
    @[AC::Param::Info(description: "Mock user ID for testing")]
    mock_user : String? = nil,
  )
    if code
      begin
        client = CasdoorClient.new
        redirect_uri = callback_url
        token = client.exchange_code_for_token(code, redirect_uri)

        # Usa o id_token (JWT) para obter informações do usuário
        if token.id_token
          user = client.get_user_info_from_jwt(token.id_token.not_nil!)

          # Verifica se veio usuário válido
          if user && (user.id || user.name).to_s.strip != ""
            # Salva apenas dados pequenos na sessão
            save_user_session(
              user.id || user.name,
              user.displayName || user.name,
              user.email || "",
              "", # não salva access_token
              user.roles
            )
            Log.info { "User logged in (casdoor): #{user.displayName || user.name}" }
            redirect_to "/auth/dashboard"
          else
            Log.warn { "OAuth callback error: Casdoor não retornou usuário válido no JWT" }
            redirect_to "/auth/error"
          end
        else
          Log.warn { "OAuth callback error: Casdoor não retornou id_token" }
          redirect_to "/auth/error"
        end
      rescue ex
        Log.warn { "OAuth callback error: #{ex.message}" }
        redirect_to "/auth/error"
      end
    elsif mock_user && (user = MOCK_USERS[mock_user]?)
      save_user_session(user["id"], user["displayName"], user["email"], "", [] of String)
      Log.info { "User logged in (mock): #{mock_user}" }
      redirect_to "/auth/dashboard"
    else
      Log.warn { "Invalid OAuth callback parameters" }
      redirect_to "/auth/login"
    end
  end

  # Dashboard - privado
  @[AC::Route::GET("/dashboard")]
  def dashboard
    require_auth
    render template: "auth/dashboard.ecr"
  end

  # Perfil - privado
  @[AC::Route::GET("/profile")]
  def profile
    require_auth
    render template: "auth/profile.ecr"
  end

  # Logout
  @[AC::Route::GET("/logout")]
  def logout
    if current_user
      Log.info { "User logged out: #{current_user.try(&.name)}" }
    end

    session.clear
    redirect_to "/auth/login"
  end

  # API para obter informações do usuário atual (JSON)
  @[AC::Route::GET("/api/me")]
  def me
    require_auth
    if user = current_user
      render json: {
        id:        user.id,
        name:      user.name,
        email:     user.email,
        roles:     user.roles,
        logged_in: true,
      }
    else
      render json: {logged_in: false}
    end
  end

  # API para verificar status de autenticação
  @[AC::Route::GET("/api/status")]
  def auth_status
    user_info = current_user.try do |user|
      {
        id: user.id,
        name: user.name,
        email: user.email,
        roles: user.roles,
      }
    end

    dto = {
      logged_in: logged_in?,
      user: user_info,
      envs: {
        casdoor_url: App::CASDOOR_URL,
        casdoor_client_id: App::CASDOOR_CLIENT_ID,
        casdoor_client_secret: App::CASDOOR_CLIENT_SECRET,
        casdoor_organization: App::CASDOOR_ORGANIZATION,
      },
    }

    render json: dto
  end

  # Simula erro de autenticação
  @[AC::Route::GET("/error")]
  def auth_error
    render template: "auth/error.ecr"
  end
end
