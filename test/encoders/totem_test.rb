require 'test/unit'
require_relative '../../lib/invoice_webgex/encoders/totem.rb'

class TestEncodersTotem < Test::Unit::TestCase
  def setup
    @order = {
      unity_code: '001',
      id: '12345',
      date: Time.now,
      total: 100.0,
      nfe: [
        { position: 1, product_code: 'prod001', quantity: 2, price: 50.0, description: 'Product 1' },
        { position: 2, product_code: 'prod002', quantity: 1, price: 50.0, description: 'Product 2' }
      ],
      employee: { code: 'emp001' },
      receiver: {
        name: 'John',
        last_name: 'Doe',
        email: 'john.doe@example.com',
        cpf: '123.456.789-00',
        phone: '1234567890'
      },
      promo_total: 0.0,
      shipment_total: 0.0
    }
    @encoder = Encoders::Totem.new(@order)
  end

  def test_encode
    result = @encoder.encode
    assert_equal(@order[:unity_code], result[:cc_fil])
    assert_equal(@order[:id], result[:cc_ped])
    assert_equal(@encoder.to_date(@order[:date]), result[:dt_ped])
    assert_equal(@encoder.to_hour(@order[:date]), result[:hr_ped])
    assert_equal(@order[:total], result[:vl_ped])
    assert_equal(@order[:nfe].length, result[:qt_ped_ite])
    assert_equal("", result[:cc_ped_fat])
    assert_equal("PD", result[:st_ped])
    assert_equal(@order.dig(:employee, :code).to_s, result[:cc_emp_vdr])
    assert_equal(-1, result[:qt_max_par])
    assert_equal(true, result[:bl_ped_fat])
    assert_equal(@encoder.items, result[:itens])
    assert_equal(@encoder.client_data, result[:cliente])
    assert_equal(@order[:promo_total], result[:valordesconto])
    assert_equal(@order[:shipment_total], result[:valorfrete])
  end

  def test_client_data
    result = @encoder.client_data
    assert_equal(@encoder.client_name, result[:nm_cli])
    assert_equal('GOC', result[:cc_org])
    assert_equal(@order[:unity_code], result[:cc_fil])
    assert_equal(@order[:receiver][:email], result[:em_cli])
    assert_equal(@order[:receiver][:cpf], result[:cc_cli_ins_fed])
    assert_equal('', result[:tx_cli_end_log])
    assert_equal('', result[:tx_cli_end_num])
    assert_equal('', result[:tx_cli_end_cmp])
    assert_equal('', result[:tx_cli_end_bai])
    assert_equal('', result[:cc_cli_end_cpt])
    assert_equal('', result[:cc_cli_end_est])
    assert_equal('', result[:tx_cli_end_mun])
    assert_equal('', result[:cc_cli_end_cge])
    assert_equal(@order[:receiver][:phone], result[:tx_cli_tel])
  end

  def test_to_date
    assert_equal(Time.now.strftime("%Y-%m-%d"), @encoder.to_date(Time.now))
  end

  def test_to_hour
    assert_equal(Time.now.strftime("%H:%M:%S"), @encoder.to_hour(Time.now))
  end

  def test_client_name
    assert_equal("John Doe", @encoder.client_name)
  end

  def test_items
    result = @encoder.items
    assert_equal(@order[:nfe].length, result.length)
    assert_equal(@order[:nfe][0][:position], result[0][:cn_ite])
    assert_equal(@order[:nfe][0][:quantity], result[0][:qt_ite])
    assert_equal(@order[:nfe][0][:price], result[0][:vl_ite_uni])
    assert_equal(0.0, result[0][:pc_ite_des])
    assert_equal(0.0, result[0][:vl_ite_des])
    assert_equal(@order[:nfe][0][:price], result[0][:vl_ite_tot])
    assert_equal("PD", result[0][:st_ped_ite])
    assert_equal("", result[0][:cc_psr_ref])
    assert_equal(@order[:nfe][0][:description], result[0][:nm_psr])
  end
end
