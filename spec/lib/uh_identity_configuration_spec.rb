require "rails_helper"
require Rails.root.join("lib/uh_identity_configuration")

RSpec.describe UhIdentityConfiguration do
  let(:options) do
    { enabled: true, issuer: "https://account.gov.uhrblx.com/",
      approved_issuer: "https://account.gov.uhrblx.com/",
      client_id: "govuh-forms-runner", private_key: "configured-key" }
  end

  it "accepts an expressly approved UH issuer" do
    expect(described_class.validate!(**options)).to be(true)
  end

  it "allows a disabled feature without authenticating" do
    expect(described_class.validate!(**options.merge(enabled: false, issuer: nil, approved_issuer: nil))).to be(true)
  end

  ["https://oidc.integration.account.gov.uk/", "https://signin.account.gov.uk/",
   "https://account.gov.uhrblx.com.attacker.example/", "http://account.gov.uhrblx.com/",
   "https://identity-unconfigured.invalid/", "not a URL"].each do |issuer|
    it "rejects unapproved issuer #{issuer}" do
      expect { described_class.validate!(**options.merge(issuer: issuer)) }.to raise_error(ArgumentError)
    end
  end

  it "rejects an issuer without independent approval" do
    expect { described_class.validate!(**options.merge(approved_issuer: nil)) }.to raise_error(ArgumentError)
  end

  it "rejects placeholder credentials" do
    expect { described_class.validate!(**options.merge(client_id: "changeme")) }.to raise_error(ArgumentError)
  end
end
