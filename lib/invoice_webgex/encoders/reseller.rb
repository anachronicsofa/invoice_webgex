module InvoiceWebgex::Encoders
  class Reseller < Base
    def initialize(order)
      @order = order.with_indifferent_access
      @order[:id] = "CLIENT-#{@order[:id]}"
      @is_reseller, @use_ipi = true, true
    end
  end
end