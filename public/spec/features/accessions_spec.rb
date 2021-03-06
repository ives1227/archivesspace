require 'spec_helper'
require 'rails_helper'

describe 'Accessions', js: true do
  it 'should show all published accessions' do
    visit('/')
    click_link 'Unprocessed Material'
    expect(current_path).to eq ('/accessions')
    finished_all_ajax_requests?
    within all('.col-sm-12')[0] do
      expect(page).to have_content("Showing Unprocessed Materials: 1 - 4 of 4")
    end
    within all('.col-sm-12')[1] do
      expect(page.all("a[class='record-title']", text: 'Published Accession').length).to eq 2
    end
  end

  it 'should not show any unpublished accessions' do
    visit('/')
    click_link 'Unprocessed Material'
    expect(current_path).to eq ('/accessions')
    finished_all_ajax_requests?
    within all('.col-sm-12')[1] do
      expect(page.all("a[class='record-title']", text: 'Unpublished Accession')).to be_empty
    end
  end

end
