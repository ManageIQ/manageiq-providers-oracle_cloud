Vmdb::Gettext::Domains.add_domain(
  'ManageIQ_Providers_OracleCloud',
  ManageIQ::Providers::OracleCloud::Engine.root.join('locale').to_s,
  :po
)
