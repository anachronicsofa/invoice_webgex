module InvoiceWebgex::Handlers
  class EnsurePrice
    class << self
      def call!(webgex_opportunity)
        total_nf = webgex_opportunity[:valor]
        total_items = webgex_opportunity[:itens].sum do |i|
          i[:valorfrete] + i[:valorunitario] * i[:quantidade]
        end

        diff = total_nf - total_items
        return if diff.abs < 0.01

        item = webgex_opportunity[:itens].min_by { |i| i[:quantidade] }

        item[:valorunitario] += diff / item[:quantidade]
        item[:valorunitario] = item[:valorunitario].round(2)
        ensure_correct_item_prices!(webgex_opportunity[:itens])
      end

      def ensure_correct_item_prices!(items)
        items.each do |i|
          total = i[:valortotal]
          computed = i[:valorfrete] + i[:valorunitario] * i[:quantidade]
          diff = total - computed

          next if diff.abs < 0.01

          i[:valortotal] = (i[:valortotal] - diff).round(2)
        end
      end
    end
  end
end