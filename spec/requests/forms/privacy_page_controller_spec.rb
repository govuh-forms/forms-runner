require "rails_helper"

RSpec.describe Forms::PrivacyPageController, type: :request do
  let(:form_id) { 2 }
  let(:privacy_policy_url) { "http://www.example.gov.uk/privacy_policy" }
  let(:privacy_notice_approved) { true }

  let(:form_data) do
    build(:form_document, :with_support,
          id: form_id,
          start_page: 1,
          privacy_policy_url: privacy_policy_url,
          what_happens_next_markdown: "Good things come to those that wait",
          declaration_markdown: "agree to the declaration",
          steps: steps_data)
  end

  let(:steps_data) do
    [
      build(:question_step,
            id: 1,
            position: 1,
            next_step_id: 2,
            type: "question",
            answer_type: "date",
            is_optional: nil,
            question_text: "Question one"),
      build(:question_step,
            id: 2,
            position: 2,
            type: "question",
            answer_type: "date",
            is_optional: nil,
            question_text: "Question two"),
    ]
  end

  let(:req_headers) { { "Accept" => "application/json" } }

  describe "#show" do
    before do
      allow(Settings.uh_forms).to receive(:privacy_notice_approved).and_return(privacy_notice_approved)

      ActiveResource::HttpMock.respond_to do |mock|
        mock.get "/api/v2/forms/#{form_id}/draft", req_headers, form_data.to_json, 200
      end

      get form_privacy_path(mode: "preview-draft", form_id: form_id, form_slug: form_data.form_slug)
    end

    it "includes the form's privacy policy URL when generic privacy content is approved" do
      expect(response.body).to include(form_data.privacy_policy_url)
      expect(response).to render_template("forms/privacy_page/show")
      expect(response).to have_http_status(:ok)
    end

    context "when the generic privacy content has not been approved" do
      let(:privacy_notice_approved) { false }

      it "keeps other forms safely unavailable" do
        expect(response).to have_http_status(:service_unavailable)
        expect(response).to render_template("errors/privacy_notice_unavailable")
      end

      context "when Form 1 has the exact published ministerial EOI privacy notice" do
        let(:form_id) { 1 }
        let(:privacy_policy_url) { Forms::PrivacyPageController::APPROVED_EXISTING_FORM_PRIVACY_NOTICES.fetch(1) }

        it "redirects to that notice without lifting the generic gate" do
          expect(response).to have_http_status(:see_other)
          expect(response).to redirect_to(privacy_policy_url)
        end
      end

      context "when another existing form uses its exact published notice" do
        {
          17 => "https://www.gov.uhrblx.com/help/privacy-notice",
          18 => "https://www.gov.uhrblx.com/government/organisations/cabinet-office/about/personal-information-charter",
          19 => "https://www.gov.uhrblx.com/government/organisations/cabinet-office/about/personal-information-charter",
          20 => "https://www.gov.uhrblx.com/government/organisations/cabinet-office/about/personal-information-charter",
        }.each do |id, notice|
          context "form #{id}" do
            let(:form_id) { id }
            let(:privacy_policy_url) { notice }

            it "redirects to the approved exact notice without lifting the generic gate" do
              expect(response).to have_http_status(:see_other)
              expect(response).to redirect_to(notice)
            end
          end
        end
      end

      context "when another form copies a permitted notice" do
        let(:form_id) { 3 }
        let(:privacy_policy_url) { "https://www.gov.uhrblx.com/help/privacy-notice" }

        it "stays unavailable because the form is not allowlisted" do
          expect(response).to have_http_status(:service_unavailable)
        end
      end

      context "when an allowlisted form has an altered notice" do
        let(:form_id) { 17 }
        let(:privacy_policy_url) { "https://www.gov.uhrblx.com.example.net/help/privacy-notice" }

        it "does not redirect to the substituted destination" do
          expect(response).to have_http_status(:service_unavailable)
        end
      end

      context "when another form tries to reuse the ministerial notice" do
        let(:privacy_policy_url) { Forms::PrivacyPageController::APPROVED_EXISTING_FORM_PRIVACY_NOTICES.fetch(1) }

        it "does not grant access" do
          expect(response).to have_http_status(:service_unavailable)
        end
      end

      context "when Form 1 has an unapproved or altered URL" do
        let(:form_id) { 1 }
        let(:privacy_policy_url) { "https://www.gov.uhrblx.com.example.org/notice" }

        it "does not follow an untrusted destination" do
          expect(response).to have_http_status(:service_unavailable)
        end
      end
    end
  end
end
