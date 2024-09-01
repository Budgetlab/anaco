class UrlToPdfJob < ApplicationJob
  queue_as :default

  def perform(url)
    tmp = Tempfile.new
    browser = Ferrum::Browser.new(headless: true,
                                  browser_options: {'no-sandbox': nil},
                                  process_timeout: 60,
                                  timeout: 200,
                                  pending_connection_errors: true)
    browser.go_to(url)
    sleep(0.3)
    browser.pdf(
      path: tmp.path,
      landscape: false,
      format: :A4,
      preferCSSPageSize: false,
      printBackground: true)
    File.read(tmp.path)
  ensure
    browser&.quit
    tmp.close
    tmp.unlink
  end
end
