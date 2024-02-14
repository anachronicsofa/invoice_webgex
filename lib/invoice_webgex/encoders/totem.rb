module InvoiceWebgex
  class Encoders::Totem
    def initialize order
      @order = order
    end

    def encode
      order_hash
    end

    def order_hash
      {	
        cc_fil:         @order[:unity_code],                      # Código da Filial (Obrigatório)
        cc_ped:         @order[:id],                              # Código Único do Pedido (Obrigatório)
        dt_ped:         to_date(@order[:date]),                   # Data do Pedido (Obrigatório)
        hr_ped:         to_hour(@order[:date]),                   # Hora do Pedido (Obrigatório)
        vl_ped:         @order[:total],                           # Valor Total do Pedido (Obrigatório)
        qt_ped_ite:     @order[:nfe].length,                      # Quantidade de Itens (Obrigatório)
        cc_ped_fat:     "",                                       # Deixar em Branco (Obrigatório)
        st_ped:         "PD",                                     # Mandar "PD" (Obrigatório)
        cc_emp_vdr:     @order.dig(:employee, :code).to_s || "",  # Código do Vendedor (Obrigatório) - Análisar Criação de Vendedor Totem ou Deixar em Branco 
        qt_max_par:     -1,                                       # Quantidade Máxima de Parcelas do Pedido (Obrigatório) - Se deixar 0, não será disponibilizada a forma de pagamento Cartão de Crédito. Se passar -1, Não haverá limitação na quantidade máxima de parcelas
        bl_ped_fat:     true,                                     # Mandar true (Obrigatório)
        itens:          items,                                    # Items,
        cliente:        client_data,                              # Dados do cliente
        valordesconto:  @order[:promo_total],                     # Desconto aplicado
        valorfrete:     @order[:shipment_total]                   # Frete adicionado
      }
    end

    def client_data
      {                                                   
        nm_cli:         client_name,                    # Nome do Cliente (Opcional)
        cc_org:         'GOC',                          # Código da Organização
        cc_fil:         @order[:unity_code],            # Código da Unidade
        em_cli:         @order[:receiver][:email],      # E-mail Cliente
        cc_cli_ins_fed: @order[:receiver][:cpf] || "",  # CPF do Cliente (Opcional)
        tx_cli_end_log: '',                             # Logradouro cliente
        tx_cli_end_num: '',                             # Número endereço cliente
        tx_cli_end_cmp: '',                             # Informações Complementares Endereço CLiente
        tx_cli_end_bai: '',                             # Bairro Cliente
        cc_cli_end_cpt: '',                             # CEP Cliente
        cc_cli_end_est: '',                             # Estado Cliente
        tx_cli_end_mun: '',                             # Cidade cliente
        cc_cli_end_cge: '',                             # Código IBGE Cliente
        tx_cli_tel:     @order[:receiver][:phone]       # Telefone Cliente
      }
    end

    def to_date date
      date.to_datetime.strftime("%Y-%m-%d")
    end

    def to_hour date
      date.to_datetime.strftime("%H:%M:%S")
    end

    def client_name
      name      = @order[:receiver][:name]
      last_name = @order[:receiver][:last_name]

      name ? "#{name} #{last_name}" : ""
    end 

    def items
      @order[:nfe].map do |item|
        item_hash item
      end
    end

    def item_hash item
      {
        cc_fil:     @order[:unity_code],          # Código da Filial (Obrigatório) - Igual do Pedido
        cc_ped:     @order[:id],                  # Código Único do Pedido (Obrigatório)
        cn_ite:     item[:position],              # Sequencia de Numeração do Item (Obrigatório)
        cc_psr:     product_code_from_pdv(item),  # Código do Item (Obrigatório)
        qt_ite:     item[:quantity],              # Quantidade do Item (Obrigatório)
        vl_ite_uni: item[:price],                 # Valor Unitário do Item (Obrigatório)
        pc_ite_des: 0.0, # solicitado enviar 0    # Percentual de Desconto do Item (Obrigatório)
        vl_ite_des: 0.0, # solicitado enviar 0    # Valor de Desconto do Item (Obrigatório)
        vl_ite_tot: item[:price],                 # Valor Total do Item (Obrigatório)
        st_ped_ite: "PD",                         # Mandar "PD" (Obrigatório)
        cc_psr_ref: "",                           # Deixar em Branco (Obrigatório)
        nm_psr:     item[:description]            # Descrição do Produto    
      }
    end

    def product_code_from_pdv(item)
      product_code = item[:product_code]
      product = Product.find_by(product_code: product_code)
      product&.unigex_code || Unigex::Pdv::ProductCode.new(product.offline_product_code).get
    end
  end
end
