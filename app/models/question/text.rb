module Question
  class Text < QuestionBase
    attribute :text
    validates :text, presence: true, unless: :is_optional?
    validates :text, length: { maximum: 499, message: :single_line_too_long }, if: :is_single_line?
    validates :text, length: { maximum: 4999, message: :long_text_too_long }, unless: :is_single_line?

    before_validation :strip_carriage_returns!, unless: :is_single_line?

    def is_single_line?
      # Some existing unpublished forms have no text answer settings. Treat
      # an unspecified type as long text rather than failing their preview.
      input_type = if answer_settings.respond_to?(:input_type)
                     answer_settings.input_type
                   elsif answer_settings.is_a?(Hash)
                     answer_settings["input_type"] || answer_settings[:input_type]
                   end

      input_type == "single_line"
    end

    def has_long_answer?
      !is_single_line?
    end

  private

    def strip_carriage_returns!
      text.presence&.gsub!(/\r\n?/, "\n")
    end
  end
end
