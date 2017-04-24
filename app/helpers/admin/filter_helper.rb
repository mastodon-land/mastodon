# frozen_string_literal: true

module Admin::FilterHelper
  ACCOUNT_FILTERS = %i[local remote by_domain by_username silenced suspended recent].freeze
  REPORT_FILTERS = %i[resolved account_id target_account_id].freeze

  FILTERS = ACCOUNT_FILTERS + REPORT_FILTERS

  def filter_link_to(text, more_params)
    new_url = filtered_url_for(more_params)
    link_to text, new_url, class: filter_link_class(new_url)
  end

  def filter_form(name)
    form_tag('', method: 'get', class: 'simple_form') do
      form_content = text_field_tag(name, params[name], placeholder: t('placeholder.search'))
      filter_params({}).each do |key, value|
        next if key == name
        form_content += hidden_field_tag(key, value)
      end
      form_content
    end
  end

  def table_link_to(icon, text, path, options = {})
    link_to safe_join([fa_icon(icon), text]), path, options.merge(class: 'table-action-link')
  end

  private

  def filter_params(more_params)
    params.permit(FILTERS).merge(more_params)
  end

  def filter_link_class(new_url)
    filtered_url_for(params) == new_url ? 'selected' : ''
  end

  def filtered_url_for(params)
    url_for filter_params(params)
  end
end
