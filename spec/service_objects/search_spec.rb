require 'rails_helper'

describe 'Search ::' do

  let(:params) { {:search => {content_search: test_text} } }
  let(:test_text) { 'test' }
  let(:language) { build(:language) }
  let(:matching_widget) { create(:text_body_widget, text_body_html: test_text) }
  let(:nonmatching_widget) { create(:text_body_widget, text_body_html: 'a non-matching text body') }
  let!(:tag) { create(:tag, tag_name: test_text, actionkit_uri: '/foo/bar') }

  describe 'PageSearcher' do

    let!(:body_match_page) {
      create(:page,
             title: 'a non-matching title',
             widgets: [matching_widget],
             language: language,
             tags: [tag]
      )
    }
    let!(:title_match_page) {
      create(:page,
             title: 'test page',
             widgets: [nonmatching_widget],
             language: language)
    }
    let(:page_searcher) { Search::PageSearcher.new(params) }

    context 'search by text content' do
      it 'gets pages that match by title or by text body if the text search method is called' do
        expect(page_searcher.search).to match_array([title_match_page, body_match_page])
      end

      it 'only gets pages that match by title if only title match method is called' do
        expect(page_searcher.search_by_title(test_text)).to match_array([title_match_page])
      end
    end

    context 'search by tag' do
      it 'searches for a page based on the tags on that page' do
        # pp 'tagid', tag.id, 'results', page_searcher.search_by_tags(tag.id).class
        expect(page_searcher.search_by_tags(tag.id)).to match_array([body_match_page])
      end

      it 'returns an empty collection when no page with the existing tags exists' do
        expect(page_searcher.search_by_tags(tag.id+1)).to eq([])
      end
    end

  end

  describe 'WidgetSearcher' do
    xit 'identifies the correct text body widget based on a search string' do

    end

    it 'searches the text of a widget and returns the found page' do
      expect(Search::WidgetSearcher.text_widget_search(test_text)).to eq([matching_widget])
    end

  end

end
