Sequel.migration do
  change do
    create_table :jobs do
      primary_key :id
      column :status, String, default: 'inprogress'
      column :created_at, Time
      column :updated_at, Time
    end

    create_table :pages do
      primary_key :id
      foreign_key :job_id, :jobs, null: false
      foreign_key :parent_id, :pages
      column :status, String, default: 'inprogress'
      column :created_at, Time
      column :updated_at, Time
      column :url, String
      column :images, 'text[]'
      column :links, 'text[]'
    end
  end
end
