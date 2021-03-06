module Admin
  class EditionFilter
    EDITION_TYPE_LOOKUP = Whitehall.edition_classes.reduce({}) do |lookup, klass|
      lookup[klass.to_s] = klass
      lookup
    end

    attr_reader :options

    def initialize(source, current_user, options={})
      @source, @current_user, @options = source, current_user, options
    end

    def editions(locale = nil)
      @editions ||= {}
      return @editions[locale] if @editions[locale]

      editions_without_translations = unpaginated_editions.includes(:last_author).order("editions.updated_at DESC")

      editions_with_translations = if locale
        editions_without_translations.with_translations(locale)
      else
        editions_without_translations.includes(:translations)
      end

      paginated_editions = editions_with_translations.page(options[:page]).per( options.fetch(:per_page) { default_page_size } )

      permitted_only = paginated_editions.select do |edition|
        Whitehall::Authority::Enforcer.new(@current_user, edition).can?(:see)
      end

      new_paginator = Kaminari.paginate_array(permitted_only, total_count: paginated_editions.total_count).page(options[:page])

      @editions[locale] = new_paginator
    end

    def page_title
      "#{ownership} #{edition_state} #{type_for_display}#{title_matches}#{location_matches} #{date_range_string}".squeeze(' ').strip
    end

    def default_page_size
      50
    end

    def show_stats
      ['published'].include?(options[:state])
    end

    def published_count
      unpaginated_editions.published.count
    end

    def force_published_count
      unpaginated_editions.force_published.count
    end

    def force_published_percentage
      if published_count > 0
        (( force_published_count.to_f / published_count.to_f) * 100.0).round(2)
      else
        0
      end
    end

    def valid?
      author
      organisation
      true
    rescue ActiveRecord::RecordNotFound
      false
    end

    def from_date
      @from_date ||= Chronic.parse(options[:from_date], endian_precedence: :little) if options[:from_date]
    end

    def to_date
      @to_date ||= Chronic.parse(options[:to_date], endian_precedence: :little) if options[:to_date]
    end

    def date_range_string
      if from_date && to_date
        "from #{from_date.to_date.to_s(:uk_short)} to #{to_date.to_date.to_s(:uk_short)}"
      elsif from_date
        "after #{from_date.to_date.to_s(:uk_short)}"
      elsif to_date
        "before #{to_date.to_date.to_s(:uk_short)}"
      end
    end

    def valid_scopes
      %w(active imported draft submitted rejected published scheduled force_published archived not_published)
    end

    private

    def unpaginated_editions
      return @unpaginated_editions if @unpaginated_editions

      editions = @source
      editions = editions.by_type(type) if type
      editions = editions.by_subtype(type, subtype) if subtype
      editions = editions.by_subtypes(type, subtype_ids) if type && subtype_ids
      editions = editions.public_send(state) if state
      editions = editions.authored_by(author) if author
      editions = editions.in_organisation(organisation) if organisation
      editions = editions.with_title_containing(title) if title
      editions = editions.in_world_location(selected_world_locations) if selected_world_locations.any?
      editions = editions.from_date(from_date) if from_date
      editions = editions.to_date(to_date) if to_date

      @unpaginated_editions = editions
    end

    def state
      options[:state] if valid_scopes.include?(options[:state])
    end

    def title
      options[:title].presence
    end

    def type
      EDITION_TYPE_LOOKUP[options[:type].sub(/_\d+$/, '').classify] if options[:type]
    end

    def subtype
      subtype_class.find_by_id(subtype_id) if type && subtype_id
    end

    def subtype_ids
      options[:subtypes].present? && options[:subtypes]
    end

    def subtype_id
      if options[:type] && options[:type][/\d+$/]
        options[:type][/\d+$/].to_i
      end
    end

    def subtype_class
      "#{type}Type".constantize
    end

    def type_for_display
      if subtype
        subtype.plural_name.downcase
      elsif type
        type.model_name.human.pluralize.downcase
      else
        "documents"
      end
    end

    def selected_world_locations
      if options[:world_location].blank?
        []
      elsif options[:world_location] == "user"
        @current_user.world_locations
      else
        [options[:world_location]]
      end
    end

    def ownership
      if author && author == @current_user
        "My"
      elsif author
        "#{author.name}'s"
      elsif organisation && organisation == @current_user.organisation
        "My department's"
      elsif organisation
        "#{organisation.name}'s"
      else
        "Everyone's"
      end
    end

    def title_matches
      " that match '#{options[:title]}'" if options[:title].present?
    end

    def edition_state
      options[:state].humanize.downcase if options[:state].present? && options[:state] != 'active'
    end

    def organisation
      Organisation.find(options[:organisation]) if options[:organisation].present?
    end

    def author
      User.find(options[:author]) if options[:author].present?
    end

    def location_matches
      if selected_world_locations.any?
        sentence = selected_world_locations.map { |l| WorldLocation.find(l).name }.to_sentence
        " about #{sentence}"
      end
    end
  end
end
