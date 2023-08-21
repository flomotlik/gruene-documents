class Document < ApplicationRecord
  belongs_to :user
  has_one_attached :file
  include PgSearch::Model

  validates :title, presence: true
  validates :file, presence: true

  after_create :extract_text

  pg_search_scope :search_body, against: :body, using: {
    tsearch: { any_word: true, dictionary: "german", prefix: true }
  }

  private

  def extract_text
    TextExtract.enqueue(self.id)
    logger.info("Job Enqueued")
  end
end
