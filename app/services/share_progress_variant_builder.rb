require 'share_progress'

class ShareProgressVariantBuilder
  def self.create(variant_type:, page:, url:, **params)
    new(params, variant_type, page, url, nil).create
  end

  def self.update(variant_type:, page:, id:, **params)
    new(params, variant_type, page, nil, id).update
  end

  def initialize(params, variant_type, page, url=nil, id=nil)
    @params = params
    @page = page
    @variant_type = variant_type.to_sym
    @url = url
    @id = id
  end

  def update
    variant = variant_class.find(@id)
    variant.assign_attributes(@params)

    return variant if (variant.changed.empty? || variant.invalid?)

    button = Share::Button.find_by(sp_type: @variant_type, page_id: @page.id)
    sp_button = ShareProgress::Button.new( share_progress_button_params(variant, button) )

    if sp_button.save
      variant.save
    else
      add_sp_errors_to_variant(sp_button, variant)
    end
    variant
  end

  def create
    variant = variant_class.new(@params)
    variant.page = @page

    return variant unless variant.valid?

    button = Share::Button.find_or_initialize_by(sp_type: @variant_type, page_id: @page.id)
    sp_button = ShareProgress::Button.new( share_progress_button_params(variant, button) )

    if sp_button.save
      button.update(sp_id: sp_button.id, sp_button_html: sp_button.share_button_html, url: sp_button.page_url)
      variant.update(sp_id:  sp_button.variants[@variant_type].last[:id])
    else
      add_sp_errors_to_variant(sp_button, variant)
    end
    variant
  end

  private

  def add_sp_errors_to_variant(sp_button, variant)
    begin
      if sp_button.errors.has_key? 'variants'
        variant.add_errors(sp_button.errors['variants'][0])
      else
        sp_button.errors.each_value do |val|
          variant.add_errors(val[0])
        end
      end
    rescue NoMethodError
      # in case SP just starts returning something wonky and the array access raises NoMethodError
      variant.add_errors([sp_button.errors.to_s])
    end
  end

  def share_progress_button_params(variant, button)
    {
      # the page_url parameter is broken now cause url isn't
      # getting stored. need a scheme of where the url is stored, and
      # maybe just a better scheme of what a button is and this file
      page_url: @url || button.url,
      button_template: "sp_#{variant_initials}_large",
      page_title: "#{@page.title} [#{@variant_type}]",
      variants: send("#{@variant_type}_variants", variant),
      id: button.sp_id
    }
  end

  def facebook_variants(variant)
    {
      facebook: [
        {
          facebook_title: variant.title,
          facebook_description: variant.description,
          facebook_thumbnail: variant.image(:facebook),
          id: variant.sp_id
        }
      ]
    }
  end


  def twitter_variants(variant)
    {
      twitter: [
        {
          twitter_message: variant.description,
          id: variant.sp_id
        }
      ]
    }
  end

  def email_variants(variant)
    {
      email: [
        {
          email_subject: variant.subject,
          email_body: variant.body,
          id: variant.sp_id
        }
      ]
    }
  end

  def variant_class
    "Share::#{@variant_type.to_s.classify}".constantize
  end

  def variant_initials
    {
      facebook: 'fb',
      twitter:  'tw',
      email:    'em'
    }[@variant_type]
  end
end

