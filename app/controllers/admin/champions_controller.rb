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

    s = params[:search_term]

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
