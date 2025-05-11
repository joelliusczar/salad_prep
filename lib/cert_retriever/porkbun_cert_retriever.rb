require_relative "./cert_retriever"
require_relative "./cert_keys"
require 'json'
require 'net/http'

module SaladPrep
	class PorkbunCertRetriever < CertRetriever

		def ssl_vars()
			data = 	<<~DATA
				{ 
					"secretapikey": "#{@egg.pb_secret}",
					"apikey": "#{@egg.pb_api_key}"
				}
			DATA

			path = "/api/json/v3/ssl/retrieve/#{"#{@egg.url_base}.#{@egg.tld}"}"
			res = Net::HTTP.start("api.porkbun.com", :use_ssl => true) do |http|
				http.post2(path, data)
			end

			json_dict = JSON.parse(res.body)

			if json_dict["status"] == "ERROR"
				raise json_dict["message"]
			end

			CertKeys.new(
				json_dict["privatekey"].chomp,
				json_dict["certificatechain"].chomp
			)
		end

	end
end