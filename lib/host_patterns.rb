module HostPatterns
  DEFAULT_HOST_PATTERNS = [
    /submit\.forms\.service\.gov\.uhrblx\.com/,
    /submit\.[^.]*\.forms\.service\.gov\.uhrblx\.com/,
    /submit\.internal.[^.]*\.forms\.service\.gov\.uhrblx\.com/,
    /pr-[^.]*\.submit\.review\.forms\.service\.gov\.uhrblx\.com/,
  ].freeze

  def self.allowed_host_patterns
    additional_patterns = ENV.fetch("ALLOWED_HOST_PATTERNS", "").split(",").map { |pattern| Regexp.new(pattern.strip) }

    [*DEFAULT_HOST_PATTERNS, *additional_patterns]
  end
end
