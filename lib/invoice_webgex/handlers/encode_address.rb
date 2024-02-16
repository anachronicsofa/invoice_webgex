module InvoiceWebgex::Handlers
  class EncodeAddress
    class << self
      def call(order)
        {
          "codpais": 1058,
          "cep": zipcode(order),
          "codmunicipio":	order[:receiver][:ibge_code],
          "logradouro":	format_address(order[:receiver][:address]),
          "numeroendereco":	format_number(order[:receiver][:number]),
          "complemento": format_complement(order[:receiver][:complement]),
          "bairro":	format_neighborhood(order[:receiver][:neighborhood]),
          "municipio": order[:receiver][:city],
          "uf": order[:receiver][:uf].presence || order[:receiver][:state]
        }
      end

      private

      def quote_string(v)
        Invoice.connection.raw_connection.escape_string(v)
      end

      def format_address(address)
        address.blank? ? "S/E" : quote_string(address[0..59])
      end
  
      def format_number(number)
        number.blank? ? "S/N" : number[0..9]
      end
  
      def format_complement(complement)
        complement.blank? ? 'S/C' : quote_string(complement[0..30])
      end

      def format_neighborhood(neighborhood)
        neighborhood.blank? || neighborhood.size < 2 ? "S/B" : quote_string(neighborhood[0..30])
      end

      def zipcode(order)
        return if order[:receiver][:zipcode].blank?
  
        zipcode = order[:receiver][:zipcode].gsub('-','')
        zipcode = zipcode.size < 8 ? "0#{zipcode}" : zipcode
        "#{zipcode[0..1]}.#{zipcode[2..4]}-#{zipcode[5..7]}"
      end
    end
  end
end