# config/initializers/grover.rb

# Déterminer le chemin de Chromium selon l'environnement
chromium_path = if ENV['PUPPETEER_EXECUTABLE_PATH'].present?
                  # Production (Hetzner) : Chromium installé via apt-get
                  ENV['PUPPETEER_EXECUTABLE_PATH']
                elsif Rails.env.development? && File.exist?('node_modules/puppeteer')
                  # Développement : Chromium de Puppeteer
                  # Puppeteer télécharge Chromium dans node_modules/.cache/puppeteer
                  require 'open3'
                  stdout, stderr, status = Open3.capture3('node -p "require(\'puppeteer\').executablePath()"')
                  if status.success?
                    stdout.strip.gsub(/^["']|["']$/, '') # Retirer les quotes
                  else
                    Rails.logger.warn "Impossible de trouver Chromium de Puppeteer: #{stderr}"
                    'chromium' # Fallback
                  end
                else
                  # Fallback : essayer chromium global
                  'chromium'
                end

Grover.configure do |config|
  config.options = {
    format: 'A4',
    margin: { top: '1cm', bottom: '1cm', left: '1cm', right: '1cm' },

    # Très important : L'URL de ton app Render pour charger le CSS/Images
    display_url: ENV.fetch('APP_URL', 'http://localhost:3000'),

    timeout: 60_000,

    # Chemin Chromium auto-détecté
    executable_path: chromium_path,

    launch_args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage', # CRITIQUE pour Docker
      '--disable-gpu',
      '--disable-software-rasterizer',
      '--disable-extensions',
      # Optimisation police d'écriture
      '--font-render-hinting=none'
    ],
    wait_until: 'networkidle2',
    print_background: true,
    prefer_css_page_size: false
  }
end