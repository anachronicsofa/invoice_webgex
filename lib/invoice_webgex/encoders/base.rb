module InvoiceWebgex::Encoders
  class Base
    def initialize(order)
      @order = order.with_indifferent_access
    end

    def encode_order
      {
        "codigopedidolegado": @order[:id],
        "codunidade":	@order[:unity_code],
        "tipo": order_type,
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
      InvoiceWebgex::Handlers::EncodeClient.call(order: @order, address: address)
    end

    def address
      InvoiceWebgex::Handlers::EncodeAddress.call(@order)
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

    def carrier_cnpj
      InvoiceWebgex::Handlers::CarrierCnpj.call(@order[:carrier_name])
    end

    def cost_result_centre
      CPF.new(cpf_cnpj).valid? ? "0104" : "0406"
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

    def order_type
      'PV'
    end

    private

    def format_date(date)
      date.to_date.strftime("%Y-%m-%d")
    end

    def format_time(date)
      date.to_datetime.strftime("%H:%M")
    end
  end
end
