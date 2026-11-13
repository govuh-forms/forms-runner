# GOV.UH Forms uses the controlled Google Workspace TLS SMTP relay rather
# than AWS SES for institutional submissions, citizen confirmations and batches.
Rails.application.config.to_prepare do
  FormSubmissionMailer.delivery_method = :smtp
  FormSubmissionMailer.smtp_settings = {
    address: "smtp-relay.gmail.com",
    port: 587,
    domain: "uhrblx.com",
    enable_starttls_auto: true,
    open_timeout: 10,
    read_timeout: 10,
  }

  [SubmissionConfirmationMailer, SubmissionBatchMailer].each do |mailer|
    mailer.delivery_method = :smtp
    mailer.smtp_settings = FormSubmissionMailer.smtp_settings
    mailer.raise_delivery_errors = true
    mailer.default from: "GOV.UH Forms <no-reply@uhrblx.com>",
                   reply_to: "no-reply@uhrblx.com"
  end

  FormSubmissionMailer.raise_delivery_errors = true
  FormSubmissionMailer.default from: "GOV.UH Forms <no-reply@uhrblx.com>",
                                reply_to: "no-reply@uhrblx.com"
end
