# lib/pagy/extras/custom.rb

#require 'pagy/extras/frontend_helpers'
require 'pagy/frontend'
class Pagy
  module Extras
    module Custom
      def pagy_nav_custom(pagy)

        html = %(<nav role="navigation" class="fr-pagination" aria-label="Pagination"><ul class="fr-pagination__list">)
        # Generate 'previous' link
        if pagy.prev
          link = pagy_anchor(pagy)
          html += %(<li>#{link.call(pagy.prev, 'Page précédente', classes: "fr-pagination__link fr-pagination__link--prev fr-pagination__link--lg-label")}</li>)
        else
          html += %(<li><a role="link" aria-disabled="true" class="fr-pagination__link fr-pagination__link--first" aria-label="Previous">Première page</a></li>)
        end
        # Generate page links
        pagy.series.each do |item|
          html.concat case item
                      when Integer
                        link = pagy_anchor(pagy)
                        %(<li>#{link.(item, classes: "fr-pagination__link")}</li>)
                      when String
                        %(<li><a role="link" class="fr-pagination__link" aria-current="page" aria-disabled="true">#{pagy.label_for(item)}</a></li>)
                      else %(<li><a class="fr-pagination__link fr-displayed-lg">…</a></li>)
                      end
        end
        # Generate 'next' link
        if pagy.next
          link = pagy_anchor(pagy)
          html += %(<li>#{link.call(pagy.next, 'Page suivante', classes: "fr-pagination__link fr-pagination__link--next fr-pagination__link--lg-label")}</li>)
        else
          html += %(<li><a role="link" aria-disabled="true" class="fr-pagination__link fr-pagination__link--last" aria-label="Next">Dernière page</a></li>)
        end
        html << %(</ul></nav>)
      end
    end
  end
  Frontend.prepend Extras::Custom
end
