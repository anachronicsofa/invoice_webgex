module InvoiceWebgex::Encoders
  class Base
    def initialize(order)
      @order = order.with_indifferent_access
      @order_type = 'PV'
      @is_reseller, @use_ipi = false, false
    end

    def encode_order
      {
        "codigopedidolegado": @order[:id],
        "codunidade":	@order[:unity_code],
        "tipo": @order_type,
        "codcentrocustoresultado": cost_result_centre,
        "cpfcnpjempregado":	"051.076.713-30",
        "cpfcnpjtransportador": carrier_cnpj,
        "valor": @order[:total],
        "datainicio": format_date(@order[:date]),
        "horainicio": format_time(@order[:date]),
        "datafim": format_date(@order[:date]),
        "horafim": format_time(@order[:date]),
        "cliente": client,
        "pagamentos": payment_data,
        "itens": encode_items
      }
    end

    def client
      {
        "nomecompleto":	@order[:receiver][:name],
        "nomefantasia":	@order[:receiver][:name],
        "naturezajuridica":	nature,
        "inscestadual": @order[:receiver][:state_registration] || "ISENTO",
        "cpfcnpj": cpf_cnpj,
        "sexo":	"F",
        "contribuinteicms": icms_contributor,
        "datanascimento": "",
        "enderecolegal": address,
        "enderecocobranca":	address,
        "contato": contact
      }
    end

    def address
      {
        "codpais": 1058,
        "cep": zipcode,
        "codmunicipio":	@order[:receiver][:ibge_code],
        "logradouro":	format_address(@order[:receiver][:address]),
        "numeroendereco":	format_number(@order[:receiver][:number]),
        "complemento": format_complement(@order[:receiver][:complement]),
        "bairro":	format_neighborhood(@order[:receiver][:neighborhood]),
        "municipio": @order[:receiver][:city],
        "uf": @order[:receiver][:uf].presence || @order[:receiver][:state]
      }
    end

    def adjust_total_price!(webgex_opportunity)
      total_invoice = webgex_opportunity[:valor]
      total_items = webgex_opportunity[:itens].sum do |item|
        item[:valorfrete] + item[:valorunitario] * item[:quantidade]
      end

      price_difference = total_invoice - total_items
      return if price_difference.abs < 0.01

      webgex_opportunity[:valor] -= price_difference 
    end

    def adjust_item_prices!(items)
      items.each do |item|
        total_price = item[:valortotal]
        calculated_price = item[:valorfrete] + item[:valorunitario] * item[:quantidade]
        price_difference = total_price - calculated_price

        next if price_difference.abs < 0.01

        item[:valortotal] = (item[:valortotal] - price_difference).round(2)
      end
    end

    def encode_items
      InvoiceWebgex::Handlers::EncodeItems.call(order: @order, is_reseller: @is_reseller, use_ipi: @use_ipi)
    end

    def payment_data
      number_of_parcels = @order[:payment_details][:number_of_parcels].to_i
      number_of_parcels = 1 if number_of_parcels.zero?
      Unigex::Payment::Parcels.new(
        total_value: @order[:total], 
        parcels: number_of_parcels, 
        due_date: @order[:date].to_date, 
        type: 'online',
        payment_details: @order[:payment_details]
      ).generate
    end

    def quote_string(v)
      Invoice.connection.raw_connection.escape_string(v)
    end

    def zipcode
      return if @order[:receiver][:zipcode].blank?

      zipcode = @order[:receiver][:zipcode].gsub('-','')
      zipcode = zipcode.size < 8 ? "0#{zipcode}" : zipcode
      "#{zipcode[0..1]}.#{zipcode[2..4]}-#{zipcode[5..7]}"
    end

    def cpf_cnpj
      if !@order[:receiver][:cpf].blank?
        cpf = CPF.new(@order[:receiver][:cpf]).formatted
        return CNPJ.new(@order[:receiver][:cpf]).formatted if !CPF.new(cpf).valid?
        cpf
      else
        CNPJ.new(@order[:receiver][:cnpj]).formatted
      end
    end

    def carrier_cnpj
      InvoiceWebgex::Handlers::CarrierCnpj.call(@order[:carrier_name])
    end

    def nature
      CPF.new(cpf_cnpj).valid? ? 'PF' : 'LT'
    end

    def cost_result_centre
      nature == "PF" ? "0104" : "0406"
    end

    private

    def format_date(date)
      date.to_date.strftime("%Y-%m-%d")
    end

    def format_time(date)
      date.to_datetime.strftime("%H:%M")
    end

    def icms_contributor
      nature == "PF" ? "N" : "S"
    end

    def contact
      {
        "celular1":	"",
        "email": @order[:receiver][:email]
      }
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
  end
end
