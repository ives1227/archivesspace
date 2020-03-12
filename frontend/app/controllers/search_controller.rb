require 'advanced_query_builder'

class SearchController < ApplicationController
  # This class provides search functionality through the frontend.  Methods
  # here generally perform a search against the backend, then render those search results
  # as JSON or HTML fragments to be rendered into tables in the application,
  # either directly in templates, or as responses to ajax calls.

  # Formatters are procs that take a fieldname, and return a proc usable as the
  # value_block argument in SearchHelper::ExtraColumn#new
  #
  # Usage:
  #       FORMATTERS[formatter].call(field)
  #
  # FORMATTERS is customized to return a default formatter if passed a format it doesn't understand,
  # which will produce the value as returned from the field without alteration.
  FORMATTERS = Hash.new do |key| proc {|field| proc {|record| record[field] } } end

  FORMATTERS.merge!(
    {
      'stringify' => proc {|field| proc {|record| record[field].to_s } },
      'linked-records-listing' => proc {|field|
        proc {|record|
          identifiers = Array(record[field])
          out_html = %Q|<ul class="linked-records-listing count-#{identifiers.length}">|
          out_html << identifiers.map {|identifier|
            %Q|<li><span class="collection-identifier">#{identifier}</span></li>|
          }.join("")
          out_html << '</ul>'

          out_html.html_safe
        }
      }
    }
  )

  set_access_control  "view_repository" => [:do_search, :advanced_search]

  include ExportHelper

  def advanced_search
    criteria = params_for_backend_search

    queries = advanced_search_queries.reject{|field|
      (field["value"].nil? || field["value"] == "") && !field["empty"]
    }

    if not queries.empty?
      criteria["aq"] = AdvancedQueryBuilder.build_query_from_form(queries).to_json
      criteria['facet[]'] = SearchResultData.BASE_FACETS
    end



    respond_to do |format|
      format.json {
        @search_data = Search.all(session[:repo_id], criteria)
        render :json => @search_data
      }
      format.js {
        @search_data = Search.all(session[:repo_id], criteria)
        if params[:listing_only]
          render_aspace_partial :partial => "search/listing"
        else
          render_aspace_partial :partial => "search/results"
        end
      }
      format.html {
        @search_data = Search.all(session[:repo_id], criteria)
        render "search/do_search"
      }
      format.csv {
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, criteria )
      }
    end
  end

  def do_search
    # Execute a backend search, rendering results as JSON/HTML fragment/HTML/CSS
    #
    # In addition to params handled by ApplicationController#params_for_backend_search, takes:
    #   :extra_columns - hash with keys 'title', 'field', 'sort_options' (hash with keys 'sortable', 'sort_by')
    #   :display_identifier - whether to display the identifier column
    #   :hide_audit_info - whether to display the updated/changed timestamps
    #   :show_context_column - whether to display the context column
    #
    #
    # 'title' in extra_columns will try to use the string as a translation key,
    #  and fall back to the raw string if there's no translation.
    #
    # For example to add uri to the data-browse field of an AJAX-backed table:
    #
    #    data-browse-url="<%= url_for :controller => :search, :action => :do_search,
    #                                 :extra_columns => [{
    #                                    'title' => 'uri',
    #                                    'formatter' =>'stringify',
    #                                    'field'=> 'uri',
    #                                    'sort_options' => {'sortable' => true, 'sort_by' => 'uri'}
    #                                  }],
    #                                  :format => :json, :facets => [], :sort => "title_sort asc" %>"
    #
    # The date-browse-url field would be identical, but with :format => :js
    #
    # Note: you will need to add an entry to frontend/config/locales under the search_sorting key for the title of any column you add

    unless request.format.csv?
      @search_data = Search.all(session[:repo_id], params_for_backend_search.merge({"facet[]" => SearchResultData.BASE_FACETS.concat(params[:facets]||[]).uniq}))
      if params[:extra_columns]
        @extra_columns = params[:extra_columns].map do |opts|
          SearchHelper::ExtraColumn.new(I18n.t(opts['title'], default: opts['title']), FORMATTERS[opts['formatter']].call(opts['field']), opts['sort_options'] || {}, @search_data)
        end
      end
      @display_identifier = params.fetch(:display_identifier, false)
      @hide_audit_info = params.fetch(:hide_audit_info, false)
      @display_context = params.fetch(:show_context_column, false)
    end

    respond_to do |format|
      format.json {
        render :json => @search_data
      }
      format.js {
        if params[:listing_only]
          render_aspace_partial :partial => "search/listing"
        else
          render_aspace_partial :partial => "search/results"
        end
      }
      format.html {
        # default render
      }
      format.csv {
        criteria = params_for_backend_search.merge({"facet[]" => SearchResultData.BASE_FACETS})
        uri = "/repositories/#{session[:repo_id]}/search"
        csv_response( uri, criteria )
      }
    end
  end


end
