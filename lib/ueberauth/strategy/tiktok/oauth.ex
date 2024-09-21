defmodule Ueberauth.Strategy.Tiktok.OAuth do
  use OAuth2.Strategy

  # Public API

  @defaults [
    strategy: __MODULE__,
    site: "https://open.tiktokapis.com/v2",
    authorize_url: "https://www.tiktok.com/v2/auth/authorize/",
    token_url: "https://open.tiktokapis.com/v2/oauth/token/"
  ]

  def get(token, url, headers \\ [], opts \\ []) do
    client(token: token)
    |> OAuth2.Client.get(url, headers, opts)
  end

  def client(opts \\ []) do
    config =
      :ueberauth
      |> Application.fetch_env!(Ueberauth.Strategy.Tiktok.OAuth)
      |> check_credential(:client_key)
      |> check_credential(:client_secret)

    # Tiktok API uses Client Key, whereas OAuth2 uses Client ID
    # Hence we need to rename the key
    config =
      Keyword.put(Keyword.delete(config, :client_key), :client_id, config[:client_key])

    client_opts =
      @defaults
      |> Keyword.merge(config)
      |> Keyword.merge(opts)

    json_library = Ueberauth.json_library()

    client_opts
    |> OAuth2.Client.new()
    |> OAuth2.Client.put_serializer("application/json", json_library)
  end

  def authorize_url!(params \\ []) do
    {code_verifier, params} = Keyword.pop!(params, :code_verifier)

    authorization_url_params =
      [
        code_challenge: :sha256 |> :crypto.hash(code_verifier) |> Base.encode64(),
        code_challenge_method: "S256"
      ] ++ params

    authorization_url_params
    |> client()
    |> OAuth2.Client.authorize_url!(authorization_url_params)
  end

  def get_token!(params \\ []) do
    client =
      client(params)
      |> put_param(:code, Keyword.get(params, :code))
      |> put_header("content-type", "application/x-www-form-urlencoded")
      # |> IO.inspect(label: "CLIENT")
      |> OAuth2.Client.get_token!()

    client.token
  end

  # Strategy Callbacks
  def authorize_url(client, params) do
    client
    |> put_param(:response_type, "code")
    |> put_param(:client_key, client.client_id)
    |> put_param(:redirect_uri, client.redirect_uri)
    |> merge_params(params)

    # OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    {code, params} = Keyword.pop(params, :code, client.params["code"])

    unless code do
      raise OAuth2.Error, reason: "Missing required key `code` for `#{inspect(__MODULE__)}`"
    end

    client
    |> put_param(:code, code)
    |> put_param(:grant_type, "authorization_code")
    |> put_param(:client_key, client.client_id)
    |> put_param(:client_secret, client.client_secret)
    |> put_param(:redirect_uri, client.redirect_uri)
    |> put_header("content-type", "application/x-www-form-urlencoded")
    |> merge_params(params)
    |> put_headers(headers)
  end

  defp check_credential(config, key) do
    check_config_key_exists(config, key)

    case Keyword.get(config, key) do
      value when is_binary(value) ->
        config

      {:system, env_key} ->
        case System.get_env(env_key) do
          nil ->
            raise "#{inspect(env_key)} missing from environment, expected in config :ueberauth, Ueberauth.Strategy.Tiktok.OAuth"

          value ->
            Keyword.put(config, key, value)
        end
    end
  end

  defp check_config_key_exists(config, key) when is_list(config) do
    unless Keyword.has_key?(config, key) do
      raise "#{inspect(key)} missing from config :ueberauth, Ueberauth.Strategy.Tiktok.OAuth"
    end

    config
  end

  defp check_config_key_exists(_, _) do
    raise "Config :ueberauth, Ueberauth.Strategy.Tiktok.OAuth is not a keyword list, as expected"
  end
end
