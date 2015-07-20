class TextBodyWidget < Widget
  include StoreWith.model

  validates :text_body_html, presence: true

  store_with :content do
    text_body_html  :string
  end
end

