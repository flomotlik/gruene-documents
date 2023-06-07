class Document < ApplicationRecord
    has_one_attached :file
    include PgSearch::Model
    validates :title, presence: true
    pg_search_scope :search_body, against: {title: 'A', body: 'B'}, using: {
        tsearch: {any_word: true, dictionary: "german", prefix: true, tsvector_column: 'searchable'}
      }
end
