require "rails_helper"

RSpec.describe "Interior Office native Garage S3 submission delivery" do
  let(:client) { Aws::S3::Client.new(stub_responses: true) }
  let(:form_id) { 3 }
  let(:formats) { %w[json] }
  let(:uploaded_questions) { [] }
  let(:form_document) do
    build(:form_document, form_id:, s3_bucket_name: "uh-interior-citizenship-submissions",
          s3_bucket_aws_account_id: nil, s3_bucket_region: "garage")
  end
  let(:submission) { build(:submission, form_document:, reference: "TEST-FORM-GARAGE-2026", mode: "form") }
  let(:delivery) { build(:delivery, formats:) }
  let(:journey) do
    instance_double(Flow::Journey, completed_file_upload_questions: uploaded_questions, all_steps: [])
  end

  around do |example|
    vars = {
      "UH_INTERIOR_GARAGE_ENDPOINT" => "http://garage.internal:3900",
      "UH_INTERIOR_GARAGE_ACCESS_KEY_ID" => "TEST-WRITE-KEY",
      "UH_INTERIOR_GARAGE_SECRET_ACCESS_KEY" => "TEST-NEVER-ACTUAL-SECRET",
    }
    previous = vars.to_h { |key, _| [key, ENV[key]] }
    vars.each { |key, value| ENV[key] = value }
    example.run
  ensure
    previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  before do
    allow(Flow::Journey).to receive(:new).and_return(journey)
    allow(Aws::S3::Client).to receive(:new).and_return(client)
    allow(CloudWatchService).to receive(:record_submission_delivery_latency_metric)
  end

  it "sends a GOV.UK native JSON submission to the dedicated Garage bucket without AWS account-owner headers or STS" do
    expect(Aws::AssumeRoleCredentials).not_to receive(:new)
    expect(client).to receive(:put_object).with(
      hash_including(
        bucket: "uh-interior-citizenship-submissions",
        key: /\Aform_submissions\/3\/\d{8}T\d{6}Z_TEST-FORM-GARAGE-2026\/form_submission\.json\z/,
        body: satisfy { |body| JSON.parse(body)["submission_reference"] == submission.reference },
      )
    )
    described_class.new(submission:, delivery:).submit
    expect(Aws::S3::Client).to have_received(:new).with(hash_including(
      endpoint: "http://garage.internal:3900", region: "garage", force_path_style: true
    ))
  end

  context "safeguards" do
    it "rejects an unapproved form ID even when the bucket name is copied" do
      allow(form_document).to receive(:form_id).and_return(5)
      expect { described_class.new(submission:, delivery:).submit }
        .to raise_error(/Interior Garage delivery is not enabled/)
    end

    it "rejects formats other than the original JSON submission contract" do
      allow(delivery).to receive(:formats).and_return(%w[csv])
      expect { described_class.new(submission:, delivery:).submit }
        .to raise_error(/native JSON submissions only/)
    end

    it "requires separate evidence-transfer approval for file uploads" do
      allow(journey).to receive(:completed_file_upload_questions).and_return([double(:file)])
      expect { described_class.new(submission:, delivery:).submit }
        .to raise_error(/approved evidence delivery route/)
    end

    it "fails closed when the private destination credentials are not configured" do
      ENV.delete("UH_INTERIOR_GARAGE_SECRET_ACCESS_KEY")
      expect { described_class.new(submission:, delivery:).submit }
        .to raise_error(/Garage upload configuration is missing/)
    end
  end
end
