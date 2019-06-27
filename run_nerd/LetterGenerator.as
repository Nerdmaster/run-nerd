// Class for simple generation of a game board's letters.
//
// Eventually this class should only let the server scramble the letters so
// that the server will at least have a way to verify letters in case cheating
// becomes a concern.  Scrambling would be done by simply returning from the
// server a list of shuffles to perform.  We would use the player's login info
// to track the scrambling of letters as well as the submitted words.  In theory
// a player could read the whole array of scrambled letters to "bot" their game,
// but trying to prevent this will be pretty much impossible anyway, so it's
// much easier to just grab the whole bag at once.
package run_nerd {
  public class LetterGenerator {
    // Number of letters available, based on http://en.wikipedia.org/wiki/Letter_frequency - giving about the
    // same number of letters as its frequency (with a minimum of 1).
    private static var LETTER_WEIGHTS = {
      A:8,    B:2,    C:2,    D:4,    E:12,
      F:2,    G:2,    H:6,    I:7,    J:1,
      K:1,    L:4,    M:2,    N:6,    O:7,
      P:2,    QU:1,   R:6,    S:6,    T:9,
      U:3,    V:1,    W:2,    X:1,    Y:2,
      Z:1
    };

    // What letters are still available for this instance
    private var letters_available:Array;

    // Constructor - sets up a default "bag" of letters
    public function LetterGenerator() {
      letters_available = LetterGenerator.build_letter_array();
    }

    // Explicitly removes certain letters
    public function remove_letters(letters_array) {
      var new_letters = new Array();

      // Go through letters_array.  Each letter must be located and removed
      // from the letters_available array.
      while (letters_array.length > 0) {
        var current_search = letters_array.pop();
        var i = letters_available.indexOf(current_search);
        if (i >= 0) {
          // Kill this element
          letters_available[i] = null;
        }
      }

      // Now we remove the nulls from the array
      letters_available = letters_available.filter(function(obj) { return (obj != null) });
    }

    // Pulls a specific number of letters, returning an array - used letters are
    // permanently removed from the "bag", so to speak.
    public function grab_letters(count) {
      var letters = new Array();

      // Scramble letters before every grab
      scramble_letter_bag();

      // Grab letters, auto-repopulating bag if necessary
      for (var x = 0; x < count; x++) {
        if (letters_left < 1) { letters_available = LetterGenerator.build_letter_array(); }
        letters.push(letters_available.pop());
      }
      return letters;
    }

    // Nice little one-letter helper
    public function grab_letter() {
      return grab_letters(1)[0];
    }

    // Just randomizes the order of our letters array
    private function scramble_letter_bag() {
      letters_available.scramble();
      letters_available.scramble();
      letters_available.scramble();
    }

    // Lets people know how many letters we have left
    public function get letters_left() {
      return letters_available.length;
    }

    // Takes the array of letters and puts them back in the bag - useful for
    // putting all the letters on the board back into the bag
    public function add_letters(letters_to_put_back) {
      letters_available = letters_available.concat(letters_to_put_back);
    }

    // Uses LETTER_WEIGHTS to build an array of all available letters.  Gives
    // us a solid place to pull letters from - take a letter, remove it from
    // the array.
    private static function build_letter_array() {
      var letters_available = new Array();

      // Go through letter weights and build letter "tiles" appropriately
      var count;
      for (var letter:String in LETTER_WEIGHTS) {
        count = LETTER_WEIGHTS[letter];
        for (var x = 0; x < count; x++) {letters_available.push(letter);}
      }

      return letters_available;
    }
  }
}
