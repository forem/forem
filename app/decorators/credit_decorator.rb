class CreditDecorator < ApplicationDecorator
  delegate_all

  def purchase_name
    return "" unless purchase_id

    purchase_type == "ClassifiedListing" ? "Listing" : ""
  end

  def purchase_description
    return "" unless purchase_id

    purchase_type == "ClassifiedListing" ? purchase.title : ""
  end
end
