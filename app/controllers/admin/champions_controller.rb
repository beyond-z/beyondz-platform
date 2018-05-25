require 'csv'

class Admin::ChampionsController < Admin::ApplicationController
  def search_synonyms
  end

  def save_search_synonyms
    # save it
    ChampionsSearchSynonym.create(
      :search_term => params[:search_term].downcase,
      :search_becomes => params[:search_becomes].downcase
    )

    # make sure there is only one key for each search term
    # FIXME

    s = params[:search_term]

    # if this creates a chain to another synonym, update them all.
    # FIXME

    # and then update any existing champions with this data
    query = Champion.where("
      array_to_string(studies, ',') ILIKE ?
      OR
      array_to_string(industries, ',') ILIKE ?",
      "%#{s}%", # for studies
      "%#{s}%"  # for industries
    )

    query.each do |c|
      c.fixup_search_synonyms
      c.save
    end

    redirect_to admin_champions_search_synonyms_path
  end

  def search_stats
  end

  def report
    @interests = {}
    Champion.all.each do |c|
      c.interests.each do |i|
        if @interests[i]
          @interests[i]["hits"] += c.hits
          @interests[i]["champs"] += 1
        else
          @interests[i] = {}
          @interests[i]["hits"] = c.hits
          @interests[i]["champs"] = 1
        end
      end
    end
  end

  def download_contacts
    respond_to do |format|
      format.html do
        render
      end
      format.csv { render text: csv_export }
    end
  end

  def csv_export
    CSV.generate do |csv|
      header = []

      header << 'Champion Name'
      header << 'Champion Email'
      header << 'Fellow Name'
      header << 'Fellow Email'

      ChampionContact.column_names.each do |cn|
        header << cn
      end

      csv << header

      ChampionContact.all.each do |cc|
        exportable = []

        champ = Champion.find(cc.champion_id)
        user = User.find(cc.user_id)
        exportable << champ.name
        exportable << champ.email
        exportable << user.name
        exportable << user.email

        cc.attributes.values_at(*ChampionContact.column_names).each do |v|
          exportable << v
        end

        csv << exportable
      end
    end
  end
end
