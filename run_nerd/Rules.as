package run_nerd {
  import com.adobe.serialization.json.*;

  // This class contains global, static rules data for Run, Nerd!  It should be
  // loaded from elsewhere, otherwise it'll just keep some defaults.
  //
  // Known rules items and what they mean:
  // * LEVEL[x]: data for a given level: "title" is what shows to user, "points" is score user needs to win,
  //   "ppl" is how fast bully moves (ppl * BULLY_MOVEMENT_LETTERS)
  // * MINIMUM_WORD_LENGTH: Words must be this many letters or more.  Kind of moot now that we load the
  //   dictionary into memory....
  // * MAXIMUM_WORD_LENGTH: Words can't be longer than this - the UI actually disables further input
  // * BULLY_MOVEMENT_LETTERS: Each submission, bully moves LEVEL[x]['ppl'] * BULLY_MOVEMENT_LETTERS
  // * PLAYER_HEADSTART: Player starts a level with level's score * PLAYER_HEADSTART points (internally)
  // * MAX_TILES: stores max bonus tiles for each type: bonus_word and bonus_super_word
  // * LONG_WORD_LEN: Length to trigger the "long words award bonus tiles" rule
  // * SUPER_LONG_WORD_LEN: Length to trigger the long words super bonus tile
  // * HIGH_PPL: PPL *above* level's PPL to trigger the "high ppl" rule
  // * HIGH_PPL_MAX_LEN: Max length of a high-ppl word to trigger the rule
  // * BULLY_SLOW_SPEED: Once high-ppl rule is triggered, bully speed is multiplied by this
  // * BULLY_SLOW_DURATION: Number of word submissions affected by bully-slowing rule
  // * RULES_LEVELS: When a given rule starts to take effect - need to alert user on prior level's completion
  // * LETTER_POINTS: Value for various letters, based on frequency groups (http://en.wikipedia.org/wiki/Letter_frequency)
  //   of my own design.  Qu is of course a special case, and I'm guessing here a bit, but giving it a high value because
  //   if you start a word with it, you aren't increasing its value (no prior clicks), whereas if you fit it in the
  //   middle of a word, you really deserve the fat boost you might get.

  public class Rules {
    private var _rules:Object;

    private static const _instance:Rules = new Rules(SingletonLock);

    // Singleton-call only
    public function Rules(lock:Class) {
      if (SingletonLock != lock) {
        throw new Error("Invalid Singleton access.  User Rules.instance instead.");
      }

      _rules = {};
    }

    public static function get instance():Rules {
      return _instance;
    }

    public function load_from_JSON(json:String) {
      _rules = JSON.decode(json);
    }

    public function rule(r:String) {
      return _rules[r];
    }

    // Probably not necessary, but allows setting a single rule manually
    public function set_rule(r:String, v:Object) {
      _rules[r] = v;
    }
  }
}

// private class to make sure nobody but us can instantiate new Rules class
class SingletonLock {}
