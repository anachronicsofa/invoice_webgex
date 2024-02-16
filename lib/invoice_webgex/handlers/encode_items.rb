module InvoiceWebgex::Handlers
  class EncodeItems
    class << self
      def call(order:, is_reseller: false, use_ipi: false)
        items = []

        order[:nfe].each do |nfe_item|
          price = use_ipi ? Order::IpiCalculator.new(nfe_item[:price], nfe_item[:ipi_percent]).calc : nfe_item[:price] 
          total = total_item_value(price, nfe_item[:quantity])
          product_code = is_reseller ? "reseller-#{nfe_item[:id]}" : nfe_item[:product_code]
          freight_value = nfe_item[:freight] ? (nfe_item[:freight] * nfe_item[:quantity]).round(2) : (item_freight(order) * nfe_item[:quantity]).round(2)
  
          item = {
            "codigoproduto": product_code,
            "quantidade":	nfe_item[:quantity],
            "valorunitario": price,
            "valordesconto": 0,
            "valorfrete": freight_value,
            "valortotal":	(total + freight_value).round(2),
            "pesounitario": nfe_item[:material_weight]
          }
  
          items << item
        end
  
        if !order[:nfs].blank?
          if nfse_total(order) != 0
            items << {
              "codigoproduto":"S000001",
              "quantidade":1,
              "valorunitario": nfse_total(order),
              "valordesconto":0,
              "valorfrete":0,
              "valortotal": nfse_total(order),
              "descricaofaturamento": order[:nfs_description]
            }
          end
        end
  
        if !use_ipi
          max_item = items.max_by { |item| item[:valortotal] }
          difference = order[:total] - items.map{|item| item[:valortotal] }.sum
          item_difference = difference / max_item[:quantidade]
  
          if is_reseller && difference < 0
            max_item[:valorunitario] = (max_item[:valorunitario] + item_difference).round(2)
          elsif is_reseller && difference > 0
            max_item[:valorfrete] = (max_item[:valorfrete] + difference).round(2)
          else
            max_item[:valorfrete] = (max_item[:valorfrete] + difference).round(2) if max_item[:valorfrete] > 0
          end
  
          max_item[:valortotal] = (max_item[:valortotal] + difference).round(2)
        end
  
        items
      end

      private

      def item_freight(order)
        items_qty = 0
        order[:nfe].each{|nfe_item| items_qty += nfe_item[:quantity]}
        ((order[:shipping] || 0 ) / items_qty.to_f).round(2)
      end

      def nfse_total(order)
        total = 0
        order[:nfs].each{|item| total += item[:price] * item[:quantity]}
        total.round(2)
      end

      def total_item_value(value, quantity)
        (value * quantity).round(2)
      end
    end
  end
end