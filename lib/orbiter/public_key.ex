defmodule Orbiter.PublicKey do

  @config_dir Application.get_env(:orbiter, :config_dir)
  @cert_file "#{@config_dir}/private_key.pem"

  def encrypt(plaintext) do
    {public_key, _} = read_keys()
    cyphertext = :public_key.encrypt_public plaintext, public_key
    cyphertext
  end

  def decrypt(cyphertext) do
    {_public_key, private_key} = read_keys()
    plaintext = :public_key.decrypt_private cyphertext, private_key
    plaintext
  end

  def public_key_der do
    {public_key, _} = read_keys()
    der = :public_key.der_encode :RSAPublicKey, public_key
    der
  end

  defp read_keys do
    unless File.exists? @cert_file do
      create_cert
    end
    {:ok, pem} = File.read @cert_file
    private_key = :public_key.pem_decode(pem) |> List.first |> :public_key.pem_entry_decode
    {:RSAPrivateKey, :'two-prime', n , e, d, _p, _q, _e1, _e2, _c, _other} = private_key
    public_key = {:RSAPublicKey, n, e}
    {public_key, private_key}
  end

  defp create_cert do
    {"", 0} = System.cmd "openssl", ["genrsa","-out", @cert_file, "2048"]
    :ok
  end

end
