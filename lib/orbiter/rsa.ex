defmodule Orbiter.RSA do

  @rsa_options [{'rsa_pad', 'rsa_pkcs1_padding'}]

  # Decrypt using the private key
	def decrypt(cyphertext, {:private, key}) do
		cyphertext |> :public_key.decrypt_private key, @rsa_options
	end

	# Decrypt using the public key
	def decrypt(cyphertext, {:public, key}) do
		cyphertext |> :public_key.decrypt_public key, @rsa_options
	end

	# Encrypt using the private key
	def encrypt(text, {:private, key}) do
		text |> :public_key.encrypt_private key, @rsa_options
	end

	# Encrypt using the public key
	def encrypt(text, {:public, key}) do
		text |> :public_key.encrypt_public key, @rsa_options
	end

  def load_key (path) do
    case File.read(path) do
      {:ok, content} -> decode_key(content)
      {:error, error} -> raise "Error :#{error} loading rsa key #{path}"
    end
  end

	# Decode a key from its text representation to a PEM structure
	def decode_key(text) do
		[entry] = text |> :public_key.pem_decode
		entry |> :public_key.pem_entry_decode
	end

end
