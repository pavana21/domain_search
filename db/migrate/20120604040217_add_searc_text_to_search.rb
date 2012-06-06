class AddSearcTextToSearch < ActiveRecord::Migration
  def change
    add_column :searches, :search_text, :string

  end
end
