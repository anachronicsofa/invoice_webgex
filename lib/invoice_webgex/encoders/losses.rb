module InvoiceWebgex::Encoders
  class Losses < Base
    def initialize(order)
      @order = order.with_indifferent_access
      @order.merge!({
        total: set_order_total, 
        unity_code: '20003'
      })
      @order_type = set_order_type
      @use_ipi = true
    end

    def payment_data
      number_of_parcels = 1
      total = @order[:nfe].map{|item| 5.00 * item[:quantity]}.sum.round(2)
      Unigex::Payment::Parcels.new(
        total_value: total,
        parcels: number_of_parcels,
        due_date: @order[:date].to_date,
        type: @type,
        payment_details:  @order[:payment_details]
      ).generate
    end

    def encode_items
      items = []

      @order[:nfe].each do |nfe_item|
        price = 0.02
        total = total_item_value(price, nfe_item[:quantity])
        product_code = nfe_item[:product_code]
        freight_value = 0

        item = {
          "codigoproduto": product_code,
          "quantidade": nfe_item[:quantity],
          "valorunitario": price,
          "valordesconto":  0,
          "valorfrete": freight_value,
          "valortotal": (total + freight_value).round(2)
        }

        items << item
      end

      items
    end

    private

    def set_order_total
      (@order[:nfe].map{|item| 0.02 * item[:quantity]}.sum * 100).floor / 100.0
    end

    def set_order_type
      return 'PR' if !@order[:id]&.include?("[manual]")

      @order[:type_of_sale] || 'PP'
    end

    def total_item_value(value, quantity)
      (value * quantity).round(2)
    end
  end
end