package run_nerd {
  // Helper class to store stats data - this could be used for per-level, per-game, and lifetime stats
  // eventually.  Encapsulates all code and data necessary to figure out what stats to store.
  //
  // TODO: Consider adding a method that takes a per-game stats object and compares it to a lifetime
  // object to get various "best" values within a single game, such as distance run, words submitted in
  // a single game, tiles used in a single game, etc.
  public class Stats {
    // The following work for level, game, or lifetime contexts
    private var _ppl:WordStat;
    private var _longest:WordStat;
    private var _highest_scoring:WordStat;
    private var _words_submitted:int;
    private var _tiles_used:int;
    private var _word_list:Array;

    // The following only make sense for game or lifetime contexts
    private var _distance_run:int;

    // The following only make sense for lifetime contexts
    private var _level_reached:int;
    private var _high_score:int;

    public function get best_ppl_word()               { return _ppl.word; }
    public function get best_ppl_word_value()         { return _ppl.val; }
    public function get longest_word()                { return _longest.word; }
    public function get longest_word_letters()        { return _longest.val; }
    public function get highest_scoring_word()        { return _highest_scoring.word; }
    public function get highest_scoring_word_value()  { return _highest_scoring.val; }
    public function get words_submitted()             { return _words_submitted; }
    public function get tiles_used()                  { return _tiles_used; }
    public function get distance_run()                { return _distance_run; }
    public function get level_reached()               { return _level_reached; }
    public function get high_score()                  { return _high_score; }
    public function get word_list()                   { return _word_list; }

    public function Stats() {
      _ppl = new WordStat();
      _longest = new WordStat();
      _highest_scoring = new WordStat();
      _words_submitted = 0;
      _tiles_used = 0;
      _distance_run = 0;
      _level_reached = 0;
      _high_score = 0;
      _word_list = new Array();
    }

    // Given our "standard" word info object, consider the word submission for stats inclusion.
    // Only words that were accepted by the game should go here, so we can always add these to
    // generic stats like _words_submitted.
    public function add_word(info:Object) {
      _words_submitted++;
      _tiles_used += info.tiles;
      _word_list.push(info);

      if (info.word.length > _longest.val) {
        _longest.word = info.word;
        _longest.val = info.word.length;
      }

      if (info.score > _highest_scoring.val) {
        _highest_scoring.word = info.word;
        _highest_scoring.val = info.score;
      }

      var ppl:Number = info.score / info.tiles;
      if (ppl > _ppl.val) {
        _ppl.word = info.word;
        _ppl.val = ppl;
      }
    }

    // Possibly alter highest level reached and high score
    public function end_game(level_num:int, score:int) {
      if (_level_reached < level_num) { _level_reached = level_num; }
      if (_high_score < score)        { _high_score = score; }
    }

    // Can't do this in add_word!  The final word of a level doesn't give us actual distance, as a
    // 1000-point word (10 meters) could be played when only 100 points are needed (1m).
    public function run(dist:int) {
      _distance_run += dist;
    }
  }
}

// Simple stat interface for "best" words
class WordStat {
  public var word:String;
  public var val:Number;

  public function WordStat() {
    word = "";
    val = 0;
  }
}
