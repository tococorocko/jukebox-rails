class LetterNumberCodes < ApplicationService
  def self.add_number_and_letter_codes(songs)
    arr = []
    code_mapping = letter_number_code_map
    songs.each_with_index do |song, index|
      arr.push(song + code_mapping[index])
    end

    to_fill = if songs.length < 60
                60
              elsif songs.length < 120
                120
              elsif songs.length < 180
                180
              elsif songs.length < 240
                240
              end

    if to_fill
      (songs.length...to_fill).to_a.each do |index|
        arr.push(["", "", ""] + code_mapping[index])
      end
    end
    arr
  end

  def self.letter_number_code_map
    num_codes = [
      [0, 48],
      [1, 49],
      [2, 50],
      [3, 51],
      [4, 52],
      [5, 53],
      [6, 54],
      [7, 55],
      [8, 56],
      [9, 57]
    ]
    letter_codes = [
      ["A", 65],
      ["B", 66],
      ["C", 67],
      ["D", 68],
      ["E", 69],
      ["F", 70],
      ["G", 71],
      ["H", 72],
      ["I", 73],
      ["J", 74],
      ["K", 75],
      ["L", 76],
      ["M", 77],
      ["N", 78],
      ["O", 79],
      ["P", 80],
      ["Q", 81],
      ["R", 82],
      ["S", 83],
      ["T", 84],
      ["U", 85],
      ["V", 86],
      ["W", 87],
      ["X", 88]
    ]
    arr = []
    letter_codes.each do |letter|
      num_codes.each do |num|
        arr.push(num + letter)
      end
    end
    arr
  end
end
