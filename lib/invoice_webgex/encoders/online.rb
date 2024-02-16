module InvoiceWebgex::Encoders
  class Online < Base
    def initialize(order)
      @order = order.with_indifferent_access
      @order[:unity_code] = '20003'
      @use_ipi = true
    end
  end
end
