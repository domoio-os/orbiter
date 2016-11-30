defmodule Orbiter.PublicKey do
  use GenServer

  @server_name :public_key

  # Client API
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: @server_name)
  end


  def encrypt(plaintext) do
    GenServer.call @server_name, {:encrypt, plaintext}
  end

  def decrypt(cyphertext) do
    GenServer.call @server_name, {:decrypt, cyphertext}
  end

  def public_key_der do
    GenServer.call @server_name, :public_key_der
  end

  def generate_keys do
    GenServer.call @server_name, :generate_keys
  end

  # Callbacks
  #----------------------------------------------------------------------

  def init(:ok) do
    {:ok, false}
  end

  def handle_call(:public_key_der, _from, {public_key, private_key}) do
    der = :public_key.der_encode :RSAPublicKey, public_key
    {:reply, der, {public_key, private_key}}
  end

  def handle_call(:generate_keys, _from, _old_keys) do
    {public_key, private_key} = generate_rsa()
    {:reply, :ok, {public_key, private_key}}
  end

  def handle_call({:decrypt, cyphertext}, _from, {public_key, private_key}) do
    plaintext = :public_key.decrypt_private cyphertext, private_key
    {:reply, plaintext, {public_key, private_key}}
  end

  def handle_call({:encrypt, plaintext}, _from, {public_key, private_key}) do
    cyphertext = :public_key.encrypt_public plaintext, public_key
    {:reply, cyphertext, {public_key, private_key}}
  end

  def generate_rsa() do
    {pem, 0} = System.cmd "openssl", ["genrsa","2048"]
    private_key = :public_key.pem_decode(pem) |> List.first |> :public_key.pem_entry_decode
    {:RSAPrivateKey, :'two-prime', n , e, d, _p, _q, _e1, _e2, _c, _other} = private_key
    public_key = {:RSAPublicKey, n, e}
    {public_key, private_key}
  end
end
