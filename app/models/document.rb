class Document < ApplicationRecord
    include PgSearch::Model
    full_text_search :search_body, against: :body, using: {
        tsearch: {any_word: true}
      }
end
