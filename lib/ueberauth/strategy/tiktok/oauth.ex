defmodule Ueberauth.Strategy.Tiktok.OAuth do
  @moduledoc """
  An implementation of OAuth2 for Tiktok.

  To add your `:client_key` and `:client_secret` include these values in your
  configuration:

      config :ueberauth, Ueberauth.Strategy.Tiktok.OAuth,
        client_key: System.get_env("TIKTOK_CLIENT_KEY"),
        client_secret: System.get_env("TIKTOK_CLIENT_SECRET")

  """

  use OAuth2.Strategy

  # Public API

  @defaults [
    strategy: __MODULE__,
    site: "https://open.tiktokapis.com/v2",
    authorize_url: "https://www.tiktok.com/v2/auth/authorize/",
    token_url: "https://open.tiktokapis.com/v2/oauth/token/"
  ]

  @doc """
  Construct a client for requests to Tiktok.

  Optionally include any OAuth2 options here to be merged with the defaults:

      Ueberauth.Strategy.Tiktok.OAuth.client(
        redirect_uri: "http://localhost:4000/auth/tiktok/callback"
      )

  This will be setup automatically for you in `Ueberauth.Strategy.Tiktok`.

  These options are only useful for usage outside the normal callback phase of
  Ueberauth.
  """
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

  @doc """
  Provides the authorize url for the request phase of Ueberauth.
  """
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

  @doc """
  Fetches the access token from Tiktok.
  """
  def get_token!(params \\ []) do
    client =
      client(params)
      |> put_param(:code, Keyword.get(params, :code))
      |> put_header("content-type", "application/x-www-form-urlencoded")
      |> OAuth2.Client.get_token!()

    client.token
  end

  @doc """
  Makes a GET request to the specified URL using the provided Tiktok token.

  ## Parameters

    - `token` (String): The OAuth token to be used for authentication.
    - `url` (String): The URL to which the GET request is made.
    - `headers` (List, optional): A list of headers to include in the request. Defaults to an empty list.
    - `opts` (List, optional): A list of options to customize the request. Defaults to an empty list.

  ## Returns

    - The response from the OAuth2 client.

  ## Examples

      iex> get("your_token", "/user/info/?fields=open_id,union_id,avatar_url,display_name")
      %OAuth2.Response{status_code: 200, body: %{"data" => %{"user" => %{"avatar_url" => "https://example.com/avatar.jpg", "display_name" => "Shapath Neupane"}}}}
  """
  def get(token, url, headers \\ [], opts \\ []) do
    client(token: token)
    |> OAuth2.Client.get(url, headers, opts)
  end

  # Strategy Callbacks

  # OAuth2.Strategy.AuthCode.authorize_url(client, params)
  # not using OAuth2.Strategy.AuthCode due to client_key vs client_id

  def authorize_url(client, params) do
    client
    |> put_param(:response_type, "code")
    |> put_param(:client_key, client.client_id)
    |> put_param(:redirect_uri, client.redirect_uri)
    |> merge_params(params)
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
