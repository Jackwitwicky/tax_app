# frozen_string_literal: true

# custom tax calculator to only apply zip code rates if present and skip state/country zones
class MyTaxCalculator
  # Create a new tax calculator.
  #
  # @param [Spree::Order] order the order to calculator taxes on
  # @return [Spree::TaxCalculator::Default] a Spree::TaxCalculator::Default object
  def initialize(order)
    @order = order
  end

  # Calculate taxes for an order.
  #
  # @return [Spree::Tax::OrderTax] the calculated taxes for the order
  def calculate
    Spree::Tax::OrderTax.new(
      order_id: order.id,
      line_item_taxes: line_item_rates,
      shipment_taxes: shipment_rates
    )
  end

  private

  attr_reader :order

  # Calculate the taxes for line items.
  #
  # @private
  # @return [Array<Spree::Tax::ItemTax>] calculated taxes for the line items
  def line_item_rates
    order.line_items.flat_map do |line_item|
      calculate_rates(line_item)
    end
  end

  # Calculate the taxes for shipments.
  #
  # @private
  # @return [Array<Spree::Tax::ItemTax>] calculated taxes for the shipments
  def shipment_rates
    order.shipments.flat_map do |shipment|
      calculate_rates(shipment)
    end
  end

  # Calculate the taxes for a single item.
  #
  # The item could be either a {Spree::LineItem} or a {Spree::Shipment}.
  #
  # Will go through all applicable rates for an item and create a new
  # {Spree::Tax::ItemTax} containing the calculated taxes for the item.
  #
  # @private
  # @return [Array<Spree::Tax::ItemTax>] calculated taxes for the item
  def calculate_rates(item)
    rates_for_item(item).map do |rate|
      amount = rate.compute_amount(item)

      Spree::Tax::ItemTax.new(
        item_id: item.id,
        label: rate.adjustment_label(amount),
        tax_rate: rate,
        amount: amount,
        included_in_price: rate.included_in_price
      )
    end
  end

  def rates_for_item(item)
    @rates_for_order = Spree::TaxRate.for_address(item.order.tax_address)
    zip_code_rates = @rates_for_order.filter { |rate| Spree::Zone.find_by(id: rate.zone_id).zipcodes.present? }

    @rates_for_order = zip_code_rates if zip_code_rates.present?

    @rates_for_order.select do |rate|
      rate.active? && rate.tax_categories.map(&:id).include?(item.tax_category_id)
    end
  end
end
