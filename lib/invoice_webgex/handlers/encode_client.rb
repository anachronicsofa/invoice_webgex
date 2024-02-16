module InvoiceWebgex::Handlers
  class EncodeClient
    class << self
      def call(order:, address: {})
        cpf_cnpj = set_cpf_cnpj(order)

        {
          "nomecompleto":	order[:receiver][:name],
          "nomefantasia":	order[:receiver][:name],
          "naturezajuridica":	nature(cpf_cnpj),
          "inscestadual": order[:receiver][:state_registration] || "ISENTO",
          "cpfcnpj": cpf_cnpj,
          "sexo":	"F",
          "contribuinteicms": icms_contributor(cpf_cnpj),
          "datanascimento": "",
          "enderecolegal": address,
          "enderecocobranca":	address,
          "contato": {
            "celular1":	"",
            "email": order[:receiver][:email]
          }
        }
      end

      private
      
      def set_cpf_cnpj(order)
        if !order[:receiver][:cpf].blank?
          cpf = CPF.new(order[:receiver][:cpf]).formatted
          return CNPJ.new(order[:receiver][:cpf]).formatted if !CPF.new(cpf).valid?
          cpf
        else
          CNPJ.new(order[:receiver][:cpf]).formatted
        end
      end

      def nature(cpf_cnpj)
        CPF.new(cpf_cnpj).valid? ? 'PF' : 'LT'
      end

      def icms_contributor(cpf_cnpj)
        nature(cpf_cnpj) == "PF" ? "N" : "S"
      end
    end
  end
end