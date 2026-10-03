# A production Forms journey must never authenticate against the UK identity service.
require "uri"

module UhIdentityConfiguration
  def self.validate!(enabled:, issuer:, approved_issuer:, client_id:, private_key:)
    return true unless enabled

    candidate = URI.parse(issuer.to_s)
    approved = URI.parse(approved_issuer.to_s)
    valid_host = candidate.host == "uhrblx.com" || candidate.host&.end_with?(".uhrblx.com")
    valid_issuer = candidate.scheme == "https" && valid_host &&
      candidate.userinfo.nil? && candidate.query.nil? && candidate.fragment.nil? &&
      candidate.to_s.chomp("/") == approved.to_s.chomp("/")
    valid_credentials = !client_id.to_s.empty? && client_id != "changeme" && !private_key.to_s.empty?
    raise ArgumentError, "Approved GOV.UH identity configuration is required" unless valid_issuer && valid_credentials

    true
  rescue URI::InvalidURIError
    raise ArgumentError, "Approved GOV.UH identity configuration is required"
  end
end
