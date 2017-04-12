class ChampionsController < ApplicationController
  layout 'public'

  before_filter :set_up_lists

  def index
  end

  def new
    @champion = Champion.new
  end

  def create
    champion = params[:champion].permit(
      :first_name,
      :last_name,
      :email,
      :phone,
      :linkedin_url,
      :braven_fellow,
      :braven_lc,
      :willing_to_be_contacted
    )

    champion[:industries] = params[:champion][:industries].reject(&:empty?)
    champion[:studies] = params[:champion][:studies].reject(&:empty?)

    n = Champion.new(champion)
    if !n.valid? || n.errors.any?
      @champion = n
      render 'new'
      return
    end
    n.save
  end

  def set_up_lists
    @industries = [
      'Accounting',
      'Advertising',
      'Aerospace',
      'Banking',
      'Beauty / Cosmetics',
      'Biotechnology ',
      'Business',
      'Chemical',
      'Communications',
      'Computer Engineering',
      'Computer Hardware ',
      'Education',
      'Electronics',
      'Employment / Human Resources',
      'Energy',
      'Fashion',
      'Film',
      'Financial Services',
      'Fine Arts',
      'Food & Beverage ',
      'Health',
      'Information Technology',
      'Insurance',
      'Journalism / News / Media',
      'Law',
      'Management / Strategic Consulting',
      'Manufacturing',
      'Medical Devices & Supplies',
      'Performing Arts ',
      'Pharmaceutical ',
      'Public Administration',
      'Public Relations',
      'Publishing',
      'Marketing ',
      'Real Estate ',
      'Sports ',
      'Technology ',
      'Telecommunications',
      'Tourism',
      'Transportation / Travel',
      'Writing'
    ]

    @fields = [
      'Accounting ',
      'African American Studies ',
      'African Studies ',
      'Agriculture ',
      'American Indian Studies ',
      'American Studies ',
      'Architecture ',
      'Asian American Studies ',
      'Asian Studies ',
      'Dance',
      'Visual Arts',
      'Theater',
      'Music',
      'English / Literature ',
      'Film',
      'Foreign Language ',
      'Graphic Design',
      'Philosophy ',
      'Religion ',
      'Business',
      'Marketing',
      'Actuarial Science',
      'Hospitality ',
      'Human Resources ',
      'Real Estate ',
      'Health',
      'Public Health ',
      'Medicine ',
      'Nursing ',
      'Gender Studies ',
      'Urban Studies ',
      'Latin American Studies ',
      'European Studies ',
      'Gay and Lesbian Studies ',
      'Latinx Studies ',
      'Women’s Studies ',
      'Education ',
      'Psychology ',
      'Child Development',
      'Computer Science ',
      'History ',
      'Biology ',
      'Cognitive Science ',
      'Human Biology ',
      'Diversity Studies ',
      'Marine Sciences ',
      'Maritime Studies ',
      'Math',
      'Nutrition ',
      'Sports and Fitness ',
      'Law / Legal Studies ',
      'Military ',
      'Public Administration ',
      'Social Work ',
      'Criminal Justice ',
      'Theology ',
      'Equestrian Studies ',
      'Food Science ',
      'Urban Planning',
      'Art History ',
      'Interior Design ',
      'Landscape Architecture ',
      'Chemistry ',
      'Physics ',
      'Chemical Engineering ',
      'Software Engineering ',
      'Industrial Engineering ',
      'Civil Engineering',
      'Electrical Engineering ',
      'Mechanical Engineering ',
      'Biomedical Engineering',
      'Computer Hardware Engineering',
      'Anatomy ',
      'Ecology ',
      'Genetics ',
      'Neurosciences',
      'Communications ',
      'Animation ',
      'Journalism ',
      'Information Technology  ',
      'Aerospace',
      'Geography',
      'Statistics ',
      'Environmental Studies ',
      'Astronomy ',
      'Public Relations',
      'Library Science',
      'Anthropology',
      'Economics',
      'Criminology',
      'Archaeology',
      'Cartography',
      'Political Science',
      'Sociology',
      'Construction Trades',
      'Culinary Arts',
      'Creative Writing'
    ]
  end
end
