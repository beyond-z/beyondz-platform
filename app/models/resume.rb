class Resume < ActiveRecord::Base
  include PgSearch

  # also has a document_type field that can be 'resume' or 'cover-letter'

  pg_search_scope :fulltext_search, against: [[:title, 'A'], [:content, 'B']], using: { tsearch: { any_word: true } }

  has_attached_file :resume
  validates_attachment :resume,
                       content_type: {
                         content_type: [
                           'application/pdf',
                           'application/msword',
                           'text/plain',
                           'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                         ],
                         message: 'is invalid: please upload either a .doc, .txt, or a .pdf file'
                       },
                       size: {
                         in: 0..2.megabytes,
                         message: 'is too large: please upload files no larger than 2 MB'
                       }

  def self.search(query)
    if query.nil?
      return all
    end
    where("(lower(title) LIKE CONCAT('%', ?, '%')) OR ? = any(tags)", query.downcase, query)
  end
end
