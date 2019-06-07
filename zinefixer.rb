# frozen_string_literal: true

require 'bundler/setup'
require 'optparse'
require 'json'
require 'set'
require 'pry'
require_relative 'lib/zinefix'

PROFILES_GLOB = File.join(__dir__, 'profiles/*.json')

list_profiles = lambda { |_dummy|
  Dir.glob(PROFILES_GLOB) do |file|
    profparsed = JSON.parse(IO.binread(file), symbolize_names: true).freeze
    profname = File.basename(file).chomp(File.extname(file))
    profdesc = profparsed[:desc]
    profmedthods = profparsed[:run_methods].join(', ')
    puts "Profil: #{profname}\n  Opis: #{profdesc}\n  Uruchamiane metody: " +
         profmedthods + "\n" * 2
  end
  exit
}
params = {}
params[:methods] = Set.new
params[:verbose] = 0
optparse = OptionParser.new do |opts|
  opts.banner = 'zine-fixer - generyczny renowator do zinów'
  opts.separator "\nUżycie: #{__FILE__} [opcje]\n"
  opts.separator 'Profile:'
  opts.on(
    '-l', '--list-profiles', 'Wylistowywuje dostępne profile, wraz z opcjami',
    &list_profiles
  )
  opts.on(
    '-p profile1,profile2,profile3','--profiles profile1,profile2,profile3',
    Array, 'Aktywuje wybrane profile (Domyślne: stable)'
  ) do |profiles|
    profiles.each do |profile|
      profile_file = File.join(__dir__, 'profiles', profile + '.json')
      unless File.exist?(profile_file)
        raise OptionParser::InvalidArgument, 'Nieznana nazwa profilu'
      end

      profile = JSON.parse(IO.binread(profile_file), symbolize_names: true)
      params[:methods].merge(profile[:run_methods].map(&:to_sym))
    end
  end
  opts.separator "\nRęczna aktywacja fixów:"
  opts.on('--downcase-filenames', 'Downcase-uje nazwy plików') do
    params[:methods].add(:downcase_filenames)
  end
  opts.on(
    '--downcase-attributes',
    'Downcase-uje ścieżki plików w atrybutach plików html'
  ) { params[:methods].add(:downcase_attributes) }
  opts.on(
    '--downcase-files-strings',
    'Downcase-uje ciągi znaków ścieżek do plików'
  ) { params[:methods].add(:downcase_files_strings) }
  opts.on(
    '--js-top',
    'Zmiana wywołań funkcji js_top'
  ) { params[:methods].add(:js_top) }
  opts.separator "\nWspólne opcje:"
  opts.on(
    '-d PATH', '--dirname PATH', String,
    'Wymagane: Ścieżka do katalogu z zinem'
  ) { |o| params[:dirname] = o }
  opts.on(
    '-v VERBOSITY', '--verbose VERBOSITY', Integer,
    'Ustawia poziom gadatliwości - domyślnie 0'
  ) { |ver| params[:verbose] = ver }
  opts.separator "\nPozostałe:"
  opts.on_tail('-h', '--help', 'Wyświetla tą pomoc') { puts optparse.to_s }
end
begin
  optparse.parse!
rescue OptionParser::InvalidArgument => e
  puts e
  exit(1)
rescue OptionParser::MissingArgument
  puts optparse.to_s
  exit
end
if params[:methods].empty?

  stable_methods = JSON.parse(
                      IO.binread(
                        File.join(__dir__, 'profiles', 'stable.json')
                      ),
                      symbolize_names: true
                    )[:run_methods].map(&:to_sym)
  params[:methods].merge(stable_methods)
end
params.freeze
if params[:dirname] && !params[:methods].empty?
  begin
    unless File.directory?(params[:dirname])
      raise "Pod ścieżką #{params[:dirname]}"\
            'nie znajduje się folder'
    end
    fixer = ZineFix.new(params[:dirname])
    all_files = Set.new.merge(Dir.glob(File.join(params[:dirname], '**/**')))
    processed_files = Set.new
    puts "[*] Przetwarzany katalog: #{params[:dirname]}" if params[:verbose] >= 2
    params[:methods].each do |pmethod|
      puts "[*] Przetwarzanie metodą: #{pmethod}..." if params[:verbose] >= 1
      fixer.method(pmethod).call do |status|
        curr_file = status[:file].downcase
        all_files << curr_file
        if status[:processed]
          processed_files << curr_file
          puts "[*] Przetworzono plik #{status[:file]}" if params[:verbose] >= 1
        elsif params[:verbose] >= 2
          puts "[*] Pominięto plik #{status[:file]}"
        end
      end
      printf("\n") if params[:verbose] >= 1
    end
    puts "Przetworzono:\n  #{processed_files.size}/#{all_files.size} " +
         File.expand_path(params[:dirname])
  rescue RuntimeError => e
    puts e
    exit(2)
  end
else
  puts optparse.to_s
end
