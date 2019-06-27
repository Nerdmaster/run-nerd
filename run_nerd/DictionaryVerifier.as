// Static class for simple verification of words.
//
// Eventually this class should periodically verify against a server, using a user's login
// to keep them from cheating and keep a tally of their expected score.
package run_nerd {
  import flash.utils.ByteArray;
  import flash.utils.Dictionary;

  public class DictionaryVerifier {
    public static var compressed:ByteArray;
    private static var _words:Dictionary;
    private static var _words_array:Array;

    // Unzips compressed data and builds a hash (Object) of words
    public static function build_wordlist() {
      compressed.uncompress();
      _words_array = compressed.toString().split("\n");
      _words = new Dictionary();
      var count:int = 0;
      _words_array.forEach(function(item) {
        _words[item] = true;
        count++;
      });

      compressed = null;
    }

    public static function verify(word:String) {
      if ('' == word || null == word) { return false }
      word = word.toLowerCase();
      return (true == _words[word]);
    }
  }
}
