require 'json'
require_relative "../box_box/box_box"
require_relative "./browser_trust_introducer"


module SaladPrep
	class FirefoxTrustIntroducer

		def create_firefox_cert_policy_file(
			public_key_file_path,
			policy_file
		)
			if /[#"'\\*]/ =~ public_key_file_path
				raise "#{public_key_file_path} contains illegal characters"
			end
			if /[#"'\\*]/ =~ policy_file
				raise "#{policy_file} contains illegal characters"
			end
			pem_file = public_key_file_path.gsub(/.crt$/, ".pem")
			content = <<~POLICY
			{
				"policies": {
					"Certificates": {
						"ImportEnterpriseRoots": true,
						"Install": [
							"#{public_key_file_path}",
							"/etc/ssl/certs/#{pem_file}"
						]
					}
				}
			}
			POLICY
			BoxBox.run_root_block do
				File.open(policy_file, "w").write(content)
			end
		end

		def get_trusted_by_firefox_json_with_added_cert(
			public_key_file_path,
			policy_content
		)
			config = JSON.parse(policy_content)
			installed = config["policies"]["Certificates"]["Install"]
			unless installed.include?(public_key_file_path)
				installed.push(public_key_file_path)
			end
			pem_file = public_key_file_path.gsub(/.crt$/, ".pem")
			unless installed.include?("/etc/ssl/certs/#{pem_file}")
				installed.push("/etc/ssl/certs/#{pem_file}")
			end
			config.to_json
		end

		def set_firefox_cert_policy(public_key_file_path)
			if /[#"'\\*]/ =~ public_key_file_path
				raise "#{public_key_file_path} contains illegal characters"
			end
			policy_file="/usr/share/firefox-esr/distribution/policies.json"
			if system("firefox", "-v", err: File::NULL)
				if File.size?(policy_file)
					BoxBox.run_root_block do
						content = get_trusted_by_firefox_json_with_added_cert(
							public_key_file_path,
							File.open(policy_file).read
						)
						File.open(policy_file, "w").write(content)
					end
				else
					create_firefox_cert_policy_file(
						public_key_file_path,
						policy_file
					)
				end
			end
		end

		def introduce_public_key(path)
			set_firefox_cert_policy(path)
		end

	end
end