class AddDomainNameInSearch < ActiveRecord::Migration
  def change
    add_column :searches, :domain_name, :string
  end

end
