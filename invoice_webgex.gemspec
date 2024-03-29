# frozen_string_literal: true

require_relative "lib/invoice_webgex/version"

Gem::Specification.new do |spec|
  spec.name = "invoice_webgex"
  spec.version = InvoiceWebgex::VERSION
  spec.authors = ["aline"]
  spec.email = ["aline.ramos@gocase.com.br"]

  spec.summary = "Gocase and Webgex Integration"
  spec.description = "Encoder and Requester used by gocase to communicate with Webgex services"
  spec.homepage = 'https://github.com/anachronicsofa/invoice_webgex'
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = "https://github.com/anachronicsofa/invoice_webgex"
  spec.metadata["source_code_uri"] = "https://github.com/anachronicsofa/invoice_webgex"
  spec.metadata["changelog_uri"] = "https://github.com/anachronicsofa/invoice_webgex"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'rails', '>= 5.0'


  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
