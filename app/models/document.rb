class Document < ApplicationRecord
    include PgSearch::Model
    pg_search_scope :search_body, against: {title: 'A', body: 'B'}, using: {
        tsearch: {any_word: true, dictionary: "german", prefix: true, tsvector_column: 'searchable'}
      }
end
