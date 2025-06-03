# config/initializers/wicked_pdf.rb
WickedPdf.configure do |config|
  # La gem wkhtmltopdf-binary inclut déjà le binaire
  # config.exe_path = sera détecté automatiquement
  config.enable_local_file_access = true

  # Options par défaut pour tous les PDFs
  config.default_options = {
    page_size: 'A4',
    print_media_type: true,
    margin: {
      top: 15,
      bottom: 15,
      left: 10,
      right: 10
    },
    encoding: 'UTF-8',
    disable_smart_shrinking: true,
    use_xserver: false,
    quiet: true,
    javascript_delay: 2000,
    window_status: 'ready',
    enable_javascript: true,
    no_stop_slow_scripts: true,
    timeout: 60 # Increase timeout to 60 seconds
  }

  # Chemin vers les assets pour wicked_pdf
  # Set root_url for all environments to ensure assets are found
  assets_dir = Rails.root.join('app', 'assets')
  config.default_options[:root_url] = "file://#{assets_dir}"

  # Add asset_path to help wicked_pdf find assets with the custom prefix
  config.default_options[:asset_path] = "/anaco/assets"
end
