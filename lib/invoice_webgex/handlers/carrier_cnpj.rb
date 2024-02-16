module InvoiceWebgex::Handlers
  class CarrierCnpj
    def self.call(carrier_name)
      case carrier_name || 'CORREIOS'
        when 'Now Logistica'                        then return '20.712.076/0001-57'
        when 'TRANSFOLHA'                           then return '58.818.022/0001-43'
        when 'TOTAL EXPRESS'                        then return '11.040.167/0001-00'
        when 'CORREIOS'                             then return '34.028.316/0001-03'
        when 'NTLOG'                                then return '29.761.819/0001-53'
        when 'FASTVIA'                              then return '26.405.676/0001-59'
        when 'LOGGI'                                then return '18.277.493/0001-77'
        when 'DIALOGO'                              then return '21.930.065/0006-10'
        when 'CARRIERS', 'INFRACOMMERCE CARRIERS'   then return '10.520.136/0001-86'
        when 'SEQUOIA'                              then return '01.599.101/0001-93'
        when 'MERCADOENVIO'                         then return '20.121.850/0019-84'
        when 'INFRACOMMERCE LOGGI'                  then return '24.217.653/0001-95'
        when 'INFRACOMMERCE TOTAL EXPRESS'          then return '73.939.449/0001-93'
      end
    end
  end
end