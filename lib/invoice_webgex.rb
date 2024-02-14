# frozen_string_literal: true

require File.expand_path('../invoice_webgex/encoders', __FILE__)

module InvoiceWebgex
  class << self
    def encode_totem(order)
      InvoiceWebgex::Encoders::Totem.new(order).encode
    end

    def hello_world
      return 'Hellow'
    end
  end
end
