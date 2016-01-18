module LazyMode
  def self.create_file(file_name, &block)
    File.new(file_name, &block)
  end

  class Agenda
    attr_accessor :notes

    def initialize
      @notes = []
     end

    def add_notes(notes_to_add)
       @notes += notes_to_add
    end

    def notes
       @notes.flatten
    end

    def filter_status(work_notes, option)
      work_notes.select! {|note| note.status == option}
    end

    def filter_tag(work_notes, option)
      work_notes.select! {|note| note.tags.include?(option)}
    end

    def filter_text(work_notes, option)
      work_notes.select! {|note|
        ! (option.match note.header).nil? ||
        ! (option.match note.body).nil?}
    end

    def where(**options)
      agenda, work_notes = Agenda.new, @notes.flatten.dup
      filter_status(work_notes, options[:status]) if ! options[:status].nil?
      filter_tag(work_notes, options[:tag]) if ! options[:tag].nil?
      filter_text(work_notes, options[:text]) if ! options[:text].nil?
      agenda.add_notes(work_notes)
      agenda
    end
  end

  class File
    attr_accessor :name, :notes

    def initialize(name, &block)
      @name = name
      @notes = []
      instance_eval(&block) if block_given?
    end

    def note(note_name, *tags, &block)
      @notes << Note.new(@name, note_name, *tags, &block)
    end

    def weekly_agenda(date)
      agenda = Agenda.new
      notes_for_agenda = weekly_agenda_helper(date)
      agenda.add_notes(notes_for_agenda)
      agenda
    end

    def daily_agenda(date)
      agenda = Agenda.new
      notes_for_agenda = daily_agenda_helper(date)
      agenda.add_notes(notes_for_agenda)
      agenda
    end

    def daily_agenda_helper(date)
      agenda = []
      tasks_with_that_date = @notes.select {|task| task.date == date}
      sub_with_that_date = @notes.map {|note| note.daily_agenda(date)}
      agenda << tasks_with_that_date
      agenda << sub_with_that_date
      agenda.flatten
    end

    def weekly_agenda_helper(date)
      agenda, dates = [], []
      (0..6).to_a.each {|x| dates << Date.create_date(date, x)}
      dates.map! {|date| daily_agenda_helper(date)}
      agenda << dates
      agenda.flatten
    end
  end

  class Date
    attr_reader :year, :month, :day, :times, :year_part

    def initialize(date_string)
      date_parts  = /\A(\w+)-(\w+)-(\w+)\z/.match(date_string)
      @year, @month, @day = date_parts[1], date_parts[2], date_parts[3]
      initialize_helper(4 - @year.length, @year) if @year.length < 4
      initialize_helper(2 - @month.length, @month) if @month.length < 2
      initialize_helper(2 - @day.length, @day) if @day.length < 2
    end

    def year
      @year.to_i
    end

    def month
      @month.to_i
    end

    def day
      @day.to_i
    end

    def to_s
      "#{@year}-#{@month}-#{@day}"
    end

    def initialize_helper(number, destination)
    number.times {destination.insert(0, "0")}
    end

    class << self
      def create_date(old, plus)
        days, months = (1..30).to_a, (1..12).to_a
        day = days[(old.day + plus - 1) % 30]
        month = months[(old.month + ((old.day + plus - 1) / 30) - 1) % 12]
        year = old.year + (old.month + ((old.day + plus - 1) / 30) - 1) / 12
        Date.new("#{year}-#{month}-#{day}")
      end
    end

    def ==(other)
      day == other.day && month == other.month && year == other.year
    end
  end

  class Note
    attr_accessor :file_name, :header, :tags, :scheduled, :status
    attr_accessor :body, :sub, :times, :part_of_the_year

    def initialize(file_name, header, *tags, &block)
      @file_name, @header, @tags = file_name, header, tags
      @status = :topostpone
      @body = ""
      @sub = []
      instance_eval(&block) if block_given?
    end

    def date
      @scheduled
    end

    def scheduled(date)
      date_string = /(\w+-\w+-\w+)( \D(\d+)(\w))?/.match date
      @scheduled = Date.new(date_string[1])
      if ! date_string[3].nil? and ! date_string[4].nil?
        @times = date_string[3]
        @part_of_the_year = date_string[4]
      end
    end

    def status(*status)
      status.size == 1 ? @status = status[0] : @status
    end

    def body(*body)
      body.size == 1 ? @body = body[0] : @body
    end

    def note(note_name, *tags, &block)
      sub << Note.new(@name, note_name, *tags, &block)
    end

    def daily_agenda(date)
      @sub.select {|s| s.date.day == date.day &&
        s.date.month == date.month && s.date.year == date.year}
    end
  end
end