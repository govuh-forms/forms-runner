class AddSmtpAcceptedAtToDeliveries < ActiveRecord::Migration[8.1]
  def change
    # The SMTP relay accepted the message; the recipient mailbox has not
    # independently confirmed delivery. Keep delivered_at reserved for that.
    add_column :deliveries, :smtp_accepted_at, :datetime
  end
end
