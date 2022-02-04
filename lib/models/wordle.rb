require 'cgi'
require 'json'
require 'rest-client'

module Models
  class Wordle
    WORD_LIST_URL = ENV['WORDLE_WORD_LIST_URL'] || 'https://raw.githubusercontent.com/powerlanguage/word-lists/master/word-list-raw.txt'

    ALPHABET = ('A'..'Z').to_a

    MARKS = {
      hit: ':large_green_square:',
      brow: ':large_yellow_square:',
      miss: ':white_large_square:'
    }

    QWERTY_KEYBOARD = [
      %w[Q W E R T Y U I O P],
      %w[A S D F G H J K L],
      %w[Z X C V B N M],
    ]

    def initialize
      @answer = self.class.words.sample
      @alphabets = ALPHABET.map { |c| [c, :none] }.to_h
      @history = []
      @answer_count = 0
      @created_at = Time.now
    end
    attr_reader :history
    attr_reader :answer_count
    attr_reader :created_at

    def valid_word?(word)
      self.class.words.include?(normalize_word(word))
    end

    def answer(word)
      @answer_count += 1
      word = normalize_word(word)
      @history.push(word)

      word == @answer ? :correct : :incorrect
    end

    def print_keyboard
      buffer = []

      QWERTY_KEYBOARD.each_with_index do |key_line, line_number|
        buffer.push(Array.new(line_number + 1).join(' '))
        key_line.each do |key|
          case @alphabets[key]
          when :hit
            buffer.push(":alphabet-yellow-#{key.downcase}:")
          when :brow
            buffer.push(":alphabet-white-#{key.downcase}:")
          when :used
            buffer.push("~#{key.downcase.tr('a-z', 'ａ-ｚ')}~ ")
          else
            buffer.push("#{key.upcase.tr('A-Z', 'Ａ-Ｚ')} ")
          end
        end
        buffer.push("\n")
      end

      buffer.join('')
    end

    def print_history
      buffer = []
      history.map do |word|
        buffer.push("#{generate_mark_and_register_keyboard(word)} #{word}")
      end
      buffer.join("\n")
    end

    private

    def normalize_word(word)
      word.strip.upcase
    end

    def generate_mark_and_register_keyboard(word)
      marks = []
      normalize_word(word).split('').zip(@answer.split('')).each do |w, a|
        if w == a
          marks.push(MARKS[:hit])
          @alphabets[w] = :hit
        elsif @answer.include?(w)
          marks.push(MARKS[:brow])
          @alphabets[w] = :brow unless @alphabets[w] == :hit
        else
          marks.push(MARKS[:miss])
          @alphabets[w] = :used if @alphabets[w] == :none
        end
      end
      marks.join('')
    end

    class << self
      def words
        @words =
          begin
            resp = RestClient.get(WORD_LIST_URL)
            resp.body
                .split(/\r?\n/)
                .map { |str| str.strip.upcase }
                .select { |str| str.match(/\A[A-Z]{5}\z/) }
                .select { |str| str.split('').uniq.size == 5 }
                .uniq
          end
      end
    end
  end
end
