# This migration comes from solidus_zip_zones (originally 20171206101152)
class AddZipcodesToSpreeZone < SolidusSupport::Migration[4.2]
  def change
    add_column :spree_zones, :zipcodes, :text
  end
end
