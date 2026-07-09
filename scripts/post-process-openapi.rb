# frozen_string_literal: true

require "yaml"

spec_path = ARGV[0] || "public/openapi/postal-admin-api.yaml"
security_scheme_name = ARGV[1] || "AdminAPIKey"
header_name = ARGV[2] || "X-Admin-API-Key"
description = ARGV[3] || "Admin API Key for authenticating with the Postal Admin API"

unless File.exist?(spec_path)
  puts "OpenAPI spec not found at #{spec_path}"
  exit 1
end

spec = YAML.load_file(spec_path)

# Ensure securitySchemes are present in components
spec["components"] ||= {}
spec["components"]["securitySchemes"] = {
  security_scheme_name => {
    "type" => "apiKey",
    "name" => header_name,
    "in" => "header",
    "description" => description
  }
}

# Add global security requirement
spec["security"] = [{ security_scheme_name => [] }]

# Ensure each path has the security requirement if it doesn't have it
# This helps Swagger UI show the lock icon on each endpoint
spec["paths"].each do |_path, methods|
  methods.each do |method, config|
    next unless method.is_a?(String) && %w[get post put patch delete].include?(method.downcase)

    config["security"] ||= [{ security_scheme_name => [] }]
  end
end

# To ensure 'security' appears at the top (well, at least after openapi/info/servers)
# we can reconstruct the hash
new_spec = {
  "openapi" => spec["openapi"],
  "info" => spec["info"],
  "servers" => spec["servers"],
  "security" => spec["security"],
  "paths" => spec["paths"],
  "components" => spec["components"]
}

File.write(spec_path, new_spec.to_yaml)
puts "Post-processed OpenAPI spec at #{spec_path} with global security scheme #{security_scheme_name}."
