require "http"
require "json"
require "base64"

# Structs para parsing de respostas do Casdoor
struct OAuthToken
  include JSON::Serializable
  getter access_token : String?
  getter id_token : String?
  getter refresh_token : String?
  getter expires_in : Int32
  getter token_type : String = "Bearer"
end

struct CasdoorUser
  # include JSON::Serializable # Removido para permitir construtor manual
  getter name : String
  getter displayName : String?
  getter email : String?
  getter avatar : String?
  getter owner : String?
  getter createdTime : String?
  getter updatedTime : String?
  getter id : String?
  getter type : String?
  getter isAdmin : Bool
  getter isGlobalAdmin : Bool
  getter isForbidden : Bool
  getter signupApplication : String?
  getter properties : Hash(String, String)?
  getter roles : Array(String)?
  getter permissions : Array(String)?

  def initialize(
    name : String,
    displayName : String? = nil,
    email : String? = nil,
    avatar : String? = nil,
    owner : String? = nil,
    createdTime : String? = nil,
    updatedTime : String? = nil,
    id : String? = nil,
    type : String? = nil,
    isAdmin : Bool = false,
    isGlobalAdmin : Bool = false,
    isForbidden : Bool = false,
    signupApplication : String? = nil,
    properties : Hash(String, String)? = nil,
    roles : Array(String)? = nil,
    permissions : Array(String)? = nil
  )
    @name = name
    @displayName = displayName
    @email = email
    @avatar = avatar
    @owner = owner
    @createdTime = createdTime
    @updatedTime = updatedTime
    @id = id
    @type = type
    @isAdmin = isAdmin
    @isGlobalAdmin = isGlobalAdmin
    @isForbidden = isForbidden
    @signupApplication = signupApplication
    @properties = properties
    @roles = roles
    @permissions = permissions
  end
end

struct CasdoorResponse(T)
  include JSON::Serializable
  getter data : T?
  getter data2 : T?
  getter msg : String?
  getter ok : Bool
end

# Cliente para comunicação com Casdoor
class CasdoorClient
  @base_url : String
  @client_id : String
  @client_secret : String
  @organization : String

  def initialize(
    @base_url = App::CASDOOR_URL,
    @client_id = App::CASDOOR_CLIENT_ID,
    @client_secret = App::CASDOOR_CLIENT_SECRET,
    @organization = App::CASDOOR_ORGANIZATION
  )
  end

  # Constrói URL de autorização OAuth
  def build_authorization_url(redirect_uri : String, state : String? = nil) : String
    params = URI::Params.build do |form|
      form.add("client_id", @client_id)
      form.add("response_type", "code")
      form.add("redirect_uri", redirect_uri)
      form.add("scope", "openid profile email")
      form.add("state", state) if state
    end

    "#{@base_url}/login/oauth/authorize?#{params}"
  end

  # Troca código de autorização por token de acesso
  def exchange_code_for_token(code : String, redirect_uri : String) : OAuthToken
    body = {
      "grant_type" => "authorization_code",
      "client_id" => @client_id,
      "client_secret" => @client_secret,
      "code" => code,
      "redirect_uri" => redirect_uri
    }

    response = HTTP::Client.post(
      "#{@base_url}/api/login/oauth/access_token",
      headers: HTTP::Headers{
        "Content-Type" => "application/json"
      },
      body: body.to_json
    )

    unless response.success?
      raise "Failed to exchange code for token: #{response.status_code} - #{response.body}"
    end

    # Debug: log da resposta do token
    Log.info { "Casdoor token response: #{response.body}" }

    OAuthToken.from_json(response.body)
  end

  # Decodifica JWT e extrai informações do usuário
  def get_user_info_from_jwt(id_token : String) : CasdoorUser
    # JWT tem formato: header.payload.signature
    parts = id_token.split('.')
    raise "Invalid JWT format" if parts.size != 3

    # Decodifica o payload (parte do meio)
    payload = parts[1]

    # Adiciona padding se necessário
    payload += "=" * (4 - payload.size % 4) if payload.size % 4 != 0

    begin
      decoded_payload = Base64.decode_string(payload)
      Log.info { "JWT payload: #{decoded_payload}" }

      # Parse do JSON do payload
      json = JSON.parse(decoded_payload)

      # Cria CasdoorUser a partir do JWT
      CasdoorUser.new(
        name: json["name"].as_s,
        displayName: json["displayName"]?.try(&.as_s),
        email: json["email"]?.try(&.as_s),
        avatar: json["avatar"]?.try(&.as_s),
        owner: json["owner"]?.try(&.as_s),
        createdTime: json["createdTime"]?.try(&.as_s),
        updatedTime: json["updatedTime"]?.try(&.as_s),
        id: json["id"]?.try(&.as_s),
        type: json["type"]?.try(&.as_s),
        isAdmin: json["isAdmin"]?.try(&.as_bool) || false,
        isGlobalAdmin: json["isGlobalAdmin"]?.try(&.as_bool) || false,
        isForbidden: json["isForbidden"]?.try(&.as_bool) || false,
        signupApplication: json["signupApplication"]?.try(&.as_s),
        properties: nil, # JWT não inclui properties
        roles: json["roles"]?.try(&.as_a.map(&.as_s)),
        permissions: json["permissions"]?.try(&.as_a.map(&.as_s))
      )
    rescue ex
      raise "Failed to decode JWT: #{ex.message}"
    end
  end

  # Obtém informações do usuário usando o token de acesso (mantido para compatibilidade)
  def get_user_info(access_token : String) : CasdoorUser
    response = HTTP::Client.get(
      "#{@base_url}/api/get-user",
      headers: HTTP::Headers{
        "Authorization" => "Bearer #{access_token}"
      }
    )

    unless response.success?
      raise "Failed to get user info: #{response.status_code} - #{response.body}"
    end

    # Debug: log da resposta do Casdoor
    Log.info { "Casdoor user info response: #{response.body}" }

    CasdoorUser.from_json(response.body)
  end

  # Valida se um token é válido
  def validate_token(access_token : String) : Bool
    begin
      get_user_info(access_token)
      true
    rescue
      false
    end
  end

  # Faz logout no Casdoor
  def logout(access_token : String) : Bool
    response = HTTP::Client.post(
      "#{@base_url}/api/logout",
      headers: HTTP::Headers{
        "Authorization" => "Bearer #{access_token}"
      }
    )

    response.success?
  end
end
