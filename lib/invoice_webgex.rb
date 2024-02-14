# frozen_string_literal: true

require 'invoice_webgex/encoders/totem'

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
