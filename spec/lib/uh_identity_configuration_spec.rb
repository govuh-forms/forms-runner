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

  describe ".approved_privacy_url" do
    it "allows a UH identity privacy document using HTTPS" do
      url = "https://account.gov.uhrblx.com/privacy"
      expect(described_class.approved_privacy_url(url)).to eq(url)
    end

    [nil, "", "https://www.gov.uk/government/publications/govuk-one-login-privacy-notice",
     "https://account.gov.uhrblx.com.evil.invalid/privacy",
     "http://account.gov.uhrblx.com/privacy",
     "https://account.gov.uhrblx.com/",
     "https://account.gov.uhrblx.com@evil.invalid/privacy",
     "https://account.gov.uhrblx.com/privacy?redirect=uk"].each do |url|
      it "rejects an unapproved external or malformed privacy URL #{url.inspect}" do
        expect(described_class.approved_privacy_url(url)).to be_nil
      end
    end
  end

  it "rejects an issuer without independent approval" do
    expect { described_class.validate!(**options.merge(approved_issuer: nil)) }.to raise_error(ArgumentError)
  end

  it "rejects placeholder credentials" do
    expect { described_class.validate!(**options.merge(client_id: "changeme")) }.to raise_error(ArgumentError)
  end
end
