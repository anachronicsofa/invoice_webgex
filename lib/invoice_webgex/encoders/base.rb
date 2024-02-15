module InvoiceWebgex::Encoders
  class Base
    def initialize(order)
      @order = order
    end

    def encode_order
      {
        "codigopedidolegado": @order[:id],
        "codunidade":	'20003',
        "tipo": 'PV',
        "codcentrocustoresultado": nature,
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
      items = []

      @order[:nfe].each do |nfe_item|
        price = nfe_item[:price] 
        total = total_item_value(price, nfe_item[:quantity])
        product_code = nfe_item[:product_code]
        freight_value = nfe_item[:freight] ? (nfe_item[:freight] * nfe_item[:quantity]).round(2) : (item_freight * nfe_item[:quantity]).round(2)

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

      if !@order[:nfs].blank?
        if nfse_total != 0
          items << {
            "codigoproduto":"S000001",
            "quantidade":1,
            "valorunitario": nfse_total,
            "valordesconto":0,
            "valorfrete":0,
            "valortotal": nfse_total,
            "descricaofaturamento": @order[:nfs_description]
          }
        end
      end

      max_item = items.max_by { |item| item[:valortotal] }
      difference = @order[:total] - items.map{|item| item[:valortotal] }.sum
      item_difference = difference / max_item[:quantidade]
      max_item[:valorfrete] = (max_item[:valorfrete] + difference).round(2) if max_item[:valorfrete] > 0
      max_item[:valortotal] = (max_item[:valortotal] + difference).round(2)

      items
    end

    def adjust_negative_item_values(items)
      interations = 0

      loop do
        interations += 1

        items.each do |item|
          item[:valorunitario] = [item[:valorunitario], 0.01].max
          item[:valortotal] = (item[:valorunitario] * item[:quantidade] + item[:valorfrete]).round(2)
        end
    
        current_total = items.sum { |item| item[:valortotal] }
        difference = @order[:total].round(2) - current_total.round(2)
    
        if difference != 0
          max_value_item = items.max_by { |item| item[:valorunitario] }
          max_value_item[:valorunitario] += (difference / max_value_item[:quantidade])
          max_value_item[:valortotal] = (max_value_item[:valorunitario] * max_value_item[:quantidade] + max_value_item[:valorfrete]).round(2)
          max_value_item[:valorunitario] = max_value_item[:valorunitario].round(2)
        end

        if interations > 1000
          raise 'Não conseguimos calcular o valor dos itens de forma que não fiquem negativo, abrir chamado.'
        end

        break if current_total.round(2) == @order[:total].round(2)
      end
    
      items
    end

    def set_items_values(items)
      difference = @order[:total] - items.map{|item| item[:valortotal] }.sum
      items.map{ |item| item.merge!(valortotal: (item[:valortotal] + difference).round(2)) }
      items.map{ |item| item.merge!(valorfrete: (item[:valorfrete] + difference).round(2)) }

      items
    end

    def item_freight
      items_qty = 0
      @order[:nfe].each{|nfe_item| items_qty += nfe_item[:quantity]}
      ((@order[:shipping] || 0 ) / items_qty.to_f).round(2)
    end

    def nfse_total
      total = 0
      @order[:nfs].each{|item| total += item[:price] * item[:quantity]}
      total.round(2)
    end

    def payment_data
      number_of_parcels = @order[:payment_details][:number_of_parcels].to_i
      number_of_parcels = 1 if number_of_parcels.nil?
      Unigex::Payment::Parcels.new(
        total_value: @order[:total], 
        parcels: number_of_parcels, 
        due_date: @order[:date].to_date, 
        type: 'online',
        payment_details: @order[:payment_details]
      ).generate
    end

    def total_item_value(value, quantity)
      (value * quantity).round(2)
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
      case @order[:carrier_name] || 'CORREIOS'
        when 'Now Logistica'                        then return '20.712.076/0001-57'
        when 'TRANSFOLHA'                           then return '58.818.022/0001-43'
        when 'TOTAL EXPRESS'                        then return '11.040.167/0001-00'
        when 'CORREIOS'                             then return '34.028.316/0001-03'
        when 'NTLOG'                                then return '29.761.819/0001-53'
        when 'FASTVIA'                              then return '26.405.676/0001-59'
        when 'LOGGI'                                then return '18.277.493/0001-77'
        when 'DIALOGO'                              then return '21.930.065/0006-10'
        when 'CARRIERS' || 'INFRACOMMERCE CARRIERS' then return '10.520.136/0001-86'
        when 'SEQUOIA'                              then return '01.599.101/0001-93'
        when 'MERCADOENVIO'                         then return '20.121.850/0019-84'
        when 'INFRACOMMERCE LOGGI'                  then return '24.217.653/0001-95'
        when 'INFRACOMMERCE TOTAL EXPRESS'          then return '73.939.449/0001-93'
      end
    end

    def nature
      CPF.new(cpf_cnpj).valid? ? 'PF' : 'LT'
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
