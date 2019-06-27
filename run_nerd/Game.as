package run_nerd {
  import flash.events.Event;
  import flash.events.MouseEvent;
  import flash.events.KeyboardEvent;
  import flash.text.*;
  import flash.display.Stage;
  import flash.display.MovieClip;
  import com.adobe.serialization.json.*;

  import run_nerd.Letter;
  import run_nerd.LetterGenerator;
  import run_nerd.DictionaryVerifier;
  import run_nerd.EndLevel;
  import run_nerd.EndGame;
  import run_nerd.MainMenu;
  import generic_code.NumberHelper;
  import generic_code.PRNG;

  public class Game {
    public static var TIME_BETWEEN_SCRAMBLES = 60;     // Frames user has to wait between scrambles

    // TODO: Figure out where to put these hints....
    private static var GENERIC_HINTS:Array = [
      'Remember to build up the points in the inner ring, and the middle tile.',
      'Pay close attention to how close you are to the bully, and how many points you\'re getting for your words.',
      'Scrambling the letters will cost you points, and each level the cost gets higher.  Only scramble when you really have to.',
      'Note the hints next to your word\'s score - it will give you an idea how valuable that word is relative to the current bully\'s speed.',
      'Pay attention to bonus tiles - they can really make a difference if used wisely!',
      'Scrambling is costly, but do\'nt avoid it blindly!  In some situations the penalty is far outweighed by the gains of having fresh letters!',
      'The number of points you get for a word gives you an idea how far you\'ll travel toward the library.',
      'Every level, the bully runs faster, so you have to keep getting smarter.',
      'Use strategy!  By dropping the tiles carefully, you can make sure that perfect word ends in the center tile, giving a huge boost to points.',
      'You can use the [ENTER] key to submit a word, and the [ESC] key to clear it.'
    ];

    // UI event handling - all clicks/keyboard presses/etc should check this
    // before processing.  See disable_ui_events for details.
    private var _ui_enabled;

    private var _stage:Stage;                               // Movie's stage
    private var _width, _height;                            // Stage's visible dimensions
    private var _menu: MainMenu;                            // Main menu object for dynamic menu fun
    private var _end_level: EndLevel;                       // End level object
    // Buttons for submit/clear word and scramble letters
    private var _enter_word_button, _clear_word_button, _scramble_letters_button;
    // Letter generator - "bag" of letters, reset per level
    private var _letter_generator:LetterGenerator;
    // Running total of player's score, temporary score for this level, score needed to beat this level.
    private var _player_score:int, _current_level_score:int, _next_level_score_needed:int;
    private var _bully_score:int;                           // Bully's current score - if he overtakes you, you lose
    private var _bully_speed:int;                           // speed at which bully moves this level
    private var _bully_slow_turns:int;                      // How long bully is slowed
    private var _nerd, _bully;                              // MovieClips to start and move when words are submitted
    private var _level;                                     // Current level
    private var _frame_count:int;                           // Number of frames we've counted since game start
    private var _last_click_frame:int;                      // When we last clicked a letter
    // arrays for letter grid
    private var _letter_columns:Array, _all_letter_buttons:Array;
    // Variables set by calling code to tell us where to position our letters grid
    private var _letter_offset_x, _letter_offset_y;
    // Labels we may have to update
    private var _score_label:TextField, _current_level_label:TextField;
    private var _slow_bully_icon:MovieClip;
    // Text field for our currently-building word
    private var _word_in_progress_label;
    // Text field for our current word's potential score (if it's a good word)
    private var _in_progress_score_label;
    // Array of letters we've previously selected
    private var _selected_letters:Array;
    private var _scramble_disable_timer;                    // If > 0, this many frames until next scramble is allowed
    private var _level_rank;                                // Current level rank string

    // per-level and per-game stats
    private var _player_level_stats:Stats, _player_game_stats:Stats;

    // Initializes all our variables to either default values or values sent
    // from options hash
    public function Game(options) {
      // Grab options
      _stage                        = options.game_stage;
      _width                        = options.width;
      _height                       = options.height;

      // Labels we update from code
      _score_label                  = options.score_label;
      _word_in_progress_label       = options.word_in_progress_label;
      _in_progress_score_label      = options.in_progress_score_label;
      _current_level_label          = options.current_level_label;

      _nerd                         = options.nerd_avatar;
      _bully                        = options.bully_avatar;

      _letter_offset_x              = options.letter_offset_x;
      _letter_offset_y              = options.letter_offset_y;

      _enter_word_button            = options.enter_word_button;
      _clear_word_button            = options.clear_word_button;
      _scramble_letters_button      = options.scramble_letters_button;

      _slow_bully_icon              = options.slow_bully;

      initialize_display();
      show_menu();
    }

    // sets up display to be the way a user sees it at the beginning of the game
    private function initialize_display() {
      // This is set up once the game is going, but needs to be hidden to start
      _slow_bully_icon.visible = false;

      _score_label.text             = 'Total Score';
      _word_in_progress_label.text  = 'Current Word';
      _in_progress_score_label.text = '(Score Info)';
      _current_level_label.text     = 'Current Grade Level';
    }

    // Creates the menu if necessary, then shows it.
    // TODO: Add FB-specific pieces if FB is enabled
    public function show_menu() {
      if (!_menu) {
        _menu = new MainMenu(_stage);
        _menu.x = 0;
        _menu.y = 0;
        _menu.add_button('Tutorial', begin_tutorial);
        _menu.add_button('Play Game', begin_game);
      }
      _menu.fade_in();
    }

    // Actually begins a game
    public function begin_game(e:Event) {
      // Kill the menu!
      _menu.fade_out();

      // FUTURE: Set up seed from NB if we're FB-enabled
      // PRNG.seed(100);

      // Set up per-game stats object
      _player_game_stats = new Stats();

      // Our various event handlers
      _enter_word_button.addEventListener(MouseEvent.CLICK, submit_word);
      _clear_word_button.addEventListener(MouseEvent.CLICK, clear_word);
      _scramble_letters_button.addEventListener(MouseEvent.CLICK, scramble_letters);
      _stage.addEventListener(Event.ENTER_FRAME, on_enter_frame);
      _stage.addEventListener(KeyboardEvent.KEY_DOWN, key_down);

      // Enable event handlers
      enable_ui_events();

      // Build the end level object
      _end_level = new EndLevel();
      _end_level.x = (_width - _end_level.width) / 2;
      _end_level.y = (_height - _end_level.height) / 2;

      // Initialize data
      _frame_count                      = 0;
      _last_click_frame                 = 0;
      _player_score                     = 0;
      _level                            = 0;
      _bully_slow_turns                 = 0;
      Letter.initialize({
        tile_offset_x:    _letter_offset_x,
        tile_offset_y:    _letter_offset_y,
        stage_width:      _width,
        stage_height:     _height
      });

      // Build our letter buttons and store them - requires a "temporary" letter bag...
      _letter_generator = new LetterGenerator;
      build_letter_grid();

      // Do all begin-level initialization
      init_level();
    }

    // After a game is over, we want to remove everything from the stage to allow for menu and such
    public function end_game_cleanup() {
      // Unregister events
      _enter_word_button.removeEventListener(MouseEvent.CLICK, submit_word);
      _clear_word_button.removeEventListener(MouseEvent.CLICK, clear_word);
      _scramble_letters_button.removeEventListener(MouseEvent.CLICK, scramble_letters);
      _stage.removeEventListener(Event.ENTER_FRAME, on_enter_frame);
      _stage.removeEventListener(KeyboardEvent.KEY_DOWN, key_down);

      // Safety measures for cleaning up stage
      if (_end_level.parent && _end_level.parent == _stage) { _stage.removeChild(_end_level); }

      // Clone (shallow) the letters array so we can manipulate the original
      var alb = _all_letter_buttons.slice();
      var size = alb.length;
      for (var count = 0; count < size; count++) {
        alb[count].destroy();
      }

      // "Free" objects for further safety
      _end_level = null;
      _letter_generator = null;

      // Change display back to normal
      initialize_display();
    }

    // Begins the simple tutorial
    public function begin_tutorial(e:Event) {
      // TODO
      trace('todo');
    }

    // Allow us to disable and re-enable the UI for things like asynchronous http hits, animations, etc
    private function disable_ui_events() {_ui_enabled = false;}
    private function enable_ui_events() {_ui_enabled = true;}

    // In case we ever need more than just a simple var, we use this function
    // to tell us if events can be processed
    private function are_ui_events_enabled() {return _ui_enabled == true;}

    // Generates letters, turns off all depressed letters, clears word list,
    // sets score to reach next level, etc.
    private function init_level() {
      // Before pulling rules, gotta increment level!
      _level++;

      // Pull rules and alias common ones
      var r = Rules.instance;
      var sr = r.rule('SCORE_REF');
      var lvl = r.rule('LEVELS');

      // Reset level stats
      _player_level_stats = new Stats();

      // We always start user with a headstart compared to bully
      _next_level_score_needed = lvl[_level]['points'] * sr;
      _current_level_score = (_next_level_score_needed * r.rule('PLAYER_HEADSTART'));
      _bully_score = 0;
      _bully_speed = Math.ceil(lvl[_level]['ppl'] * r.rule('BULLY_MOVEMENT_LETTERS') * sr);

      _level_rank = lvl[_level]['title'];
      _current_level_label.text = _level_rank;

      // set up letters, clear word list, clear word
      _selected_letters = new Array();

      // Set up word, temp score, and button scores
      recalc_word_and_score();
      recalc_unused_letter_scores();

      // update stats labels
      update_stat_labels();

      // Show "bonus info" screen to explain rules that pop up on each level
      var bonus_text;
      var rl = r.rule('RULES_LEVELS');
      switch(_level) {
        case rl['word_bonus_tiles']:
          bonus_text = 'The bully gets faster every grade, but now you have special "super nerd" tiles to speed ' +
              'yourself up as well!  You get one each level, but never more than ' + r.rule('MAX_TILES')['bonus_word'] +
              ' at a time.  So use them, but use them wisely.';
          break;

        case rl['long_words_bonus_tile']:
          bonus_text = 'You\'re smarter than ever, but the bully is getting really fast thanks to off-season ' +
              'track training!  To even things out, you can now earn extra bonus tiles by using really long words - ' +
              'even if they aren\'t worth many points!';
          break;

        case rl['high_ppl_slow']:
          bonus_text = 'Using long words is fine to get a little speed boost, but you can now REALLY confuse the bully ' +
              'by using short but high-scoring words!';
          break;
      }

      if (null == bonus_text) {
        init_level_part2();
        return;
      }

      var bi = new BonusInfo();
      bi.bonus_text = bonus_text;
      bi.on_animation_complete = init_level_part2;
      bi.begin(_stage);
    }

    // Gets current bully speed, factoring in slow effect if present
    private function bully_speed() {
      return _bully_speed * ((0 == _bully_slow_turns) ? 1 : Rules.instance.rule('BULLY_SLOW_SPEED'));
    }

    // Looks up rule, compares to current level, sees if it's on or not
    private function rule_enacted(rule:String):Boolean {
      var rl = Rules.instance.rule('RULES_LEVELS');
      if (rl[rule]) {
        return (_level >= rl[rule]);
      }

      trace('Trying to look up invalid rule, "' + rule + '"!');
      return false;
    }

    private function init_level_part2() {
      // If we're at the right level for it, create a bonus word tile
      if (rule_enacted('word_bonus_tiles')) {
        award_bonus_tile(Letter.BONUS_WORD);
      }
    }

    // Chooses a tile at random and award it a tile of the give bonus type
    private function award_bonus_tile(type:int):Boolean {
      // TODO: If it makes sense, pull this into a lookup in Letter class
      var type_str:String = '';
      switch(type) {
        case Letter.BONUS_WORD:
          type_str = 'bonus_word';
          break;

        case Letter.BONUS_SUPER_WORD:
          type_str = 'bonus_super_word';
          break;
      }
      if (Letter.bonus_tiles(type) >= Rules.instance.rule('MAX_TILES')[type_str]) {return false;}

      // Clone (shallow) the letters array so we can manipulate the original
      var alb = _all_letter_buttons.slice();
      alb.scramble();
      var done = false;
      while (alb.length > 0) {
        var l = alb.pop();
        if (l.can_make_bonus_type(type)) {
          l.make_bonus_type(type);
          return true;
        }
      }

      trace('Unable to apply a bonus - all letters failed can_make_bonus_type() check!');
      return false;
    }

    private function key_down(e:KeyboardEvent) {
      // If we aren't supposed to be getting events, ignore this
      if (!are_ui_events_enabled() ) {return;}

      switch(e.keyCode) {
        case 13:
          submit_word(e);
          break;

        case 27:
          clear_word(e);
          break;
      }
    }

    // Show very simple stats
    private function update_stat_labels() {
      _score_label.text = NumberHelper.comma_format(_player_score);
    }

    // One-time function used to build the letter objects that are needed to
    // display the letters for the game board.
    private function build_letter_grid() {
      _all_letter_buttons = new Array();
      _letter_columns = new Array();

      // Build our game board's letters
      for (var i = 0; i < 5; i++) {
        _letter_columns[i] = new Array();
        for (var j = 0; j < 7; j++) {
          drop_letter_in_column(i);
        }
      }
    }

    // Given a column, pushes a letter onto its top.  Fails if there are already the maximum letters in the
    // given column.  Otherwise, creates a letter tile at random, pulls its letter from the bag, and
    // puts it above the top of the letter below it in this column
    private function drop_letter_in_column(col:int) {
      // Which row will we eventually occupy?  Return here if row is invalid
      var letters = _letter_columns[col];
      // Find the first null via reverse traversal to determine where we'll go
      var row = null;
      for (var x = 6; x >= 0; x--) {
        if (null == letters[x]) {
          row = x;
          break;
        }
      }

      if (null == row) {return 0;}

      // Get the letter directly below us
      var letter_below = (row < 6) ? letters[row+1] : null;

      var letter = _letter_generator.grab_letter();
      var l = new run_nerd.Letter(col, row - 2, letter, _stage);

      if (letter_below && letter_below.y < 0) {
        l.y = letter_below.y - Letter.HEIGHT * 1.5;
      }
      l.addEventListener(MouseEvent.CLICK, letter_button_clicked);

      // For ease of grabbing all buttons, push the letter into our all
      // buttons array
      _all_letter_buttons.push(l);
      letters[row] = l;
    }

    // A letter was clicked - if it's unused, add it to our list of selected
    // letters, update our score, update the score of all our board's letters,
    // and set it to used.  If it's used and the most recent letter chosen,
    // remove it from our list of letters and do the same updating as above.
    // If used but not most recent, do nothing.
    private function letter_button_clicked(e:MouseEvent) {
      // Most double-clicks are an accident (or some funky bug) - ignore them
      if (_last_click_frame + 5 >= _frame_count) { return; }
      _last_click_frame = _frame_count;

      // If we aren't supposed to be getting events, ignore this
      if (!are_ui_events_enabled() ) {return;}

      var letter = e.currentTarget;

      // TEST: UNCOMMENT FOR TESTING BONUS TILES
      //if (e.ctrlKey && e.altKey) {letter.make_bonus_type(Letter.BONUS_WORD) }

      if (!letter.is_used) {
        // Letter isn't in use.  Validate letter is selectable
        if (can_select_letter(letter)) {
          // TODO: Add "zap" code here - if shift is pressed while clicking (or right-click hack?), remove some points
          // and start a simple animation (disable ui) for 1/2 second or so (15 frames) to remove the letter in an
          // interesting way

          // Grab it, add to word in progress, update score in progress, update
          // used status, recalc score for all unused letters on the board.
          add_to_word(letter);
        }
      }
      else {
        // This letter is in use.  Remove all letters in use after this one.
        remove_from_word(letter);
      }
    }

    // Updates our selected letters array, recomputes in-progress score, and
    // updates all necessary display fields.
    private function add_to_word(l:Letter) {
      // Handy little alias
      var sl = _selected_letters;

      // Toggle button for our letter, then add it to the selected letters array
      l.toggle_button(true);
      sl.push(l);

      // Now run through selected letters array to get our temp score and build
      // out our word for the label
      recalc_word_and_score();

      // Finally, we must recalculate the scores of all letters on the board
      // that aren't selected.
      recalc_unused_letter_scores();
    }

    // Uses get_in_progress_word_and_score to update text labels for word/score
    private function recalc_word_and_score() {
      var info = get_in_progress_word_and_score();

      // Set labels
      _word_in_progress_label.text = info.word;
      if (info.word_is_valid) {
        _in_progress_score_label.text = '+' + NumberHelper.comma_format(info.score);
        _in_progress_score_label.text += '   ' + get_word_value_hint_text(info.score);
      }
      else {
        _in_progress_score_label.text = "";
      }

      // Show that we can take more letters via the underscore, if size is < max
      if (info.tiles < Rules.instance.rule('MAXIMUM_WORD_LENGTH')) {_word_in_progress_label.text += '_';}
    }

    // Given a score, shows the value of the given word relative to the bully's movement, winning, losing, etc.
    private function get_word_value_hint_text(score:int) {
      var hints = [
        ':-{',      // LOSE!
        ':-(',      // losing at least SCORE_REF ground
        ':-/',      // not much progress (if any) *and* close to bully
        ':-|',      // not much progress (if any)
        ':-)',      // make some progress
        'B-)',      // move a lot
        ':-D'       // WIN!
      ];
      return hints[get_word_value_hint(score)];
    }

    // Gives a 0-6 indicator of a word's worth, where 0 is a loss, 6 is a win, and values in between *try* to be a
    // decent indication of relative worth of the word.
    // TODO: Move various constants into rules JSON somehow....
    private function get_word_value_hint(score: int) {
      // Various cases to check - order matters here A LOT.
      var new_player = score + _current_level_score;
      var new_bully = _bully_score + bully_speed();
      var curr_dist = _current_level_score - _bully_score;
      var new_dist = new_player - new_bully;

      // Alias reference point since we use it quite a bit below
      var ref = Rules.instance.rule('SCORE_REF');

      if (testwin(new_player))                            { return 6; }           // Winning is good
      if (testlose(new_player, new_bully))                { return 0; }           // Losing is not
      if (Math.abs(curr_dist - new_dist) < ref)           { return 3; }           // No real change in distance is meh
      if (curr_dist > new_dist)                           { return 1; }           // Bully gains on you by a bit
      if (curr_dist <= (3*ref) && new_dist <= (4*ref))    { return 2; }           // Bully is too close, need to widen the gap
      if ((new_dist - curr_dist) > (5*ref))               { return 5; }           // We get a good lead over our current distance
      return 4;                                                                   // We make progress
    }

    // Returns true if the given score would win - basically a waste of space, but nice alias and centralization
    private function testwin(score:int) { return score >= _next_level_score_needed; }

    // Returns true if the given score would lose to the given bully's score - centralizes hard-coded distance check
    private function testlose(score:int, bully:int) { return  bully + Rules.instance.rule('SCORE_REF') >= score; }

    // Dynamically builds word in progress from our used letters, and returns
    // it as a string, and the score.
    private function get_in_progress_word_and_score() {
      // Handy little alias
      var sl = _selected_letters;
      var r = Rules.instance;
      var ref = r.rule('SCORE_REF');

      var size = sl.length;
      var temp_word = '';
      var temp_score:Number = 0;
      var bonus_value:Number = 1;
      for (var x = 0; x < size; x++) {
        temp_word += sl[x].letter;
        temp_score += sl[x].tile_value;
        if (sl[x].is_bonus_word_tile() ) {bonus_value += r.rule('BONUS_TILE_VALUE');}
        if (sl[x].is_bonus_super_word_tile() ) {bonus_value += r.rule('SUPER_BONUS_TILE_VALUE');}
      }
      var final_score:int = NumberHelper.round_to(temp_score * bonus_value, ref / 4);
      return {
        word:           temp_word,
        score:          final_score,
        tiles:          size,
        word_is_valid:  DictionaryVerifier.verify(temp_word),
        base_ppl:       (temp_score / size / ref)
      };
    }

    // Counts up the number of middle & outer letters selected and uses them to
    // tell each unused letter to recalculate its score
    private function recalc_unused_letter_scores() {
      // Handy little alias
      var sl = _selected_letters;
      var alb = _all_letter_buttons;

      // First get counts of selected letter types
      var size = sl.length;
      var outer = 0;
      var middle = 0;
      for (var x = 0; x < size; x++) {
        switch (sl[x].letter_type) {
          case Letter.TYPE_OUTER:
            outer++;
            break;
          case Letter.TYPE_MIDDLE:
            middle++;
            break;
        }
      }

      // Now recalc all unused letters on the board
      var board_size = alb.length;
      for (x = 0; x < board_size; x++) { alb[x].compute_score(outer, middle); }
    }

    // Removes this letter from the word, and all letters after it
    private function remove_from_word(l:Letter) {
      // Clone doesn't work, but calling slice does return a new array, so....
      var old_sl = _selected_letters.slice();

      // Clear out the board as if we were just starting a new word
      clear_word();

      var size = old_sl.length;
      var found = false;
      for (var x = 0; x < size; x++) {
        if (old_sl[x] == l) {
          break;
        }

        add_to_word(old_sl[x]);
      }

      // And of course, recalc the thing.
      recalc_word_and_score();
    }

    // Submits the word to our dictionary object.  If valid, updates our score,
    // adds word to this level's list, clears our current word, grabs new
    // letters to replace the old, and recalculates everything (word's temp
    // score, word's text, letter scores back to base, etc).
    private function submit_word(e:Event) {
      // Rules alias
      var r = Rules.instance;

      // If we aren't supposed to be getting events, ignore this
      if (!are_ui_events_enabled() ) {return;}

      // Check if word is valid via our dictionary class.
      //
      // TODO: In the future we'll want to send word + score somewhere every now and then, possibly randomly, along
      // with game's starting seed.  That way anybody with super high scores could be audited (though game would
      // still be so trivial to automate "legitimately"....)
      var info = get_in_progress_word_and_score();

      // Don't allow submission if word isn't valid - check word info, and call dictionary's verify method
      // just to be extra safe
      if (!info.word_is_valid || !DictionaryVerifier.verify(info.word)) {
        reject_word();
        return;
      }

      // Check for setting (or resetting) bully's slow status
      if ((info.base_ppl >= r.rule('LEVELS')[_level]['ppl'] + r.rule('HIGH_PPL')) &&
          info.tiles <= r.rule('HIGH_PPL_MAX_LEN') && rule_enacted('high_ppl_slow'))
      {
        trace('Adding slow effect');
        _bully_slow_turns = r.rule('BULLY_SLOW_DURATION');
      }

      // update scores
      _player_score += info.score;
      _current_level_score += info.score;

      // update stats if it makes sense
      _player_level_stats.add_word(info);
      _player_game_stats.add_word(info);

      // Clear the selected letters, drop in new letters
      destroy_selected_letters();

      update_stat_labels();

      // Check for long/super long words to award bonus/super bonus tiles - must be done AFTER deleting word
      // FUTURE: Allow tile upgrade?
      if (info.tiles >= r.rule('LONG_WORD_LEN') && rule_enacted('long_words_bonus_tile')) {
        if (info.tiles >= r.rule('SUPER_LONG_WORD_LEN')) {
          // If we can't award a super tile, try to award a normal tile instead
          if (!award_bonus_tile(Letter.BONUS_SUPER_WORD)) {
            award_bonus_tile(Letter.BONUS_WORD);
          }
        }
        else {
          award_bonus_tile(Letter.BONUS_WORD);
        }
      }

      if (testwin(_current_level_score)) {
        animate_to_next_level();
        return;
      }

      // Bully only moves if we didn't just win
      _bully_score += bully_speed();
      if (_bully_slow_turns > 0) { trace('Decrementing _bully_slow_turns'); _bully_slow_turns--; }
    }

    // Helper to convert a score to meters - score is decameters * ref
    private function to_meters(score:int) { return Math.ceil(score / Rules.instance.rule('SCORE_REF')) * 10; }

    // Show the EndLevel movie clip to congratulate player (as well as break
    // down score).  When it's done, tell it to call our actual end level code.
    private function animate_to_next_level() {
      disable_ui_events();
      _stage.addChild(_end_level);

      var ref = Rules.instance.rule('SCORE_REF');

      // Update game's overall running distance
      _player_game_stats.run(to_meters(_next_level_score_needed));

      // Bonus is based on distance from bully at end of level
      var dist:int = _next_level_score_needed - _bully_score;
      var bonus:int = NumberHelper.round_to(Math.max(ref / 4, dist / 5 * (1 + _level / 10.0)), ref / 4);

      //// Send over data for the labels ////

      // Distance is decameters * ref score, so we need to divide by ref and multiply by 10
      _end_level.lead_value         = to_meters(dist);
      _end_level.old_score_value    = _player_score;
      _end_level.bonus_value        = bonus;
      _end_level.level_name         = _level_rank;
      _end_level.stats              = _player_level_stats;

      // Apply bonus
      _player_score += bonus;

      // Point the finish function to our start_next_level function
      _end_level.on_finish_animation  = start_next_level;

      // GO!
      _end_level.begin_score_animations();
    }

    // Removes the end level object from the stage and initializes the level
    private function start_next_level() {
      _stage.removeChild(_end_level);
      init_level();
      enable_ui_events();
    }

    // Rejects a word submission
    private function reject_word() {
      // TODO: Make noise if invalid word
    }

    // Removes and rebuilds all letters on the board
    private function scramble_letters(e:Event) {
      // If we aren't supposed to be getting events, ignore this
      if (!are_ui_events_enabled() ) {return;}

      // Can't scramble more than every few seconds - too annoying on the UI
      if (_scramble_disable_timer > 0) {return;}
      _scramble_disable_timer = TIME_BETWEEN_SCRAMBLES;
      _scramble_letters_button.mouseEnabled = false;

      // Clone (shallow) the letters array so we can manipulate the original
      var alb = _all_letter_buttons.slice();
      var size = alb.length;

      // If we're attempting to scramble, no point storing our word.
      clear_word();

      for (var count = 0; count < size; count++) {
        destroy_letter(alb[count]);
      }

      // It's not free to scramble (2.5x on level 1, +x per level after)...
      _player_score -= (1.5 + _level) * Rules.instance.rule('SCORE_REF');
      // ...unless your score is already zero, of course
      if (_player_score < 0) {_player_score = 0;}

      update_stat_labels();
    }

    // Destroys the given letter, alerting all others in the same column that they must fall, and drops in a new
    // letter
    private function destroy_letter(letter) {
        _all_letter_buttons.splice(_all_letter_buttons.indexOf(letter), 1);
        // Drop all letters above the destroyed and make row 0 null
        var col = _letter_columns[letter.col];
        for (var x = letter.row + 2; x >= 0; x--) {
          col[x].drop_row();
          if (x > 0) {col[x] = col[x-1];}
        }
        col[0] = null;

        letter.destroy();
        drop_letter_in_column(letter.col)
    }

    // Calls destroy_letter for all currently selected letters
    private function destroy_selected_letters() {
      // Shallow-clone old array to be safe
      var old_selected:Array = _selected_letters.slice();
      clear_word();
      old_selected.forEach(function(item) {destroy_letter(item);});
    }

    // Frame-based stuff for simple animations to make the game ever-so-slightly
    // more interesting
    private function on_enter_frame(e:Event) {
      _frame_count++;

      // Show slow bully icon?
      _slow_bully_icon.visible = false;
      if (_bully_slow_turns > 0) {
        _slow_bully_icon.visible = true;
        if (_bully_slow_turns > (Rules.instance.rule('BULLY_SLOW_DURATION') * 0.5)) {
          _slow_bully_icon.alpha = 1;
        }
        else if (_bully_slow_turns > 1) {
          _slow_bully_icon.alpha = (_frame_count % 30 < 15) ? 1 : 0.50;
        }
        else {
          _slow_bully_icon.alpha = (_frame_count % 8 < 4) ? 1 : 0.50;
        }
      }

      // Scramble will be allowed again when this reaches 0
      if (_scramble_disable_timer > 0) {
        _scramble_disable_timer--;
        _scramble_letters_button.alpha = (_scramble_disable_timer % 10 < 5) ? 1 : 0.25;
        if (0 == _scramble_disable_timer) {
          _scramble_letters_button.alpha = 1;
          _scramble_letters_button.mouseEnabled = true;
        }
      }

      animate_avatar(_nerd, _current_level_score);
      animate_avatar(_bully, _bully_score);

      // Did we lose?  TODO: Animate loss, submit score, show final end-level-like window, go to main menu
      if (testlose(_current_level_score, _bully_score)) {
        // Clear the game board
        end_game_cleanup();

        // Final update to game's stats
        _player_game_stats.run(to_meters(_current_level_score));
        _player_game_stats.end_game(_level, _player_score);

        // Create EndGame object
        var eg = new EndGame();
        eg.stage      = _stage;
        eg.stats      = _player_game_stats;
        eg.level_name = _level_rank;
        eg.on_close   = show_menu;
        eg.fade_in();
      }

      // Animate letters falling
      var alb = _all_letter_buttons;
      var size = alb.length;
      for(var x = 0; x < size; x++) {
        alb[x].on_enter_frame(e);
      }
    }

    // Given a clip and score, determines where to animate the clip based on max score for the level
    private function animate_avatar(avatar, score:int) {
      var new_frame:int = avatar.totalFrames * score / _next_level_score_needed;
      var curr_frame = avatar.currentFrame;
      if (new_frame < 1) new_frame = 1;
      if (new_frame == curr_frame) return;

      var movement_direction = (curr_frame < new_frame) ? 1 : -1;
      var movement_amount = Math.ceil(Math.abs(curr_frame - new_frame) / 10);
      avatar.gotoAndStop(curr_frame + movement_direction * movement_amount);
    }

    // Clears out the current selected letters array and unpresses all letter
    // buttons.  Then recalculates word, temp score, and board letter scores.
    // Has one parameter that's unused in order to allow the mouse click event
    // to call it.
    private function clear_word(e:Event = null) {
      // If we aren't supposed to be getting events, ignore this
      if (!are_ui_events_enabled() ) {return;}

      _selected_letters.forEach(function(item) {item.toggle_button(false);});
      _selected_letters = new Array();
      recalc_word_and_score();
      recalc_unused_letter_scores();
    }

    // Validation function for a given letter.  Follows certain rules to
    // determine if a letter can be selected:
    // * Cannot have more than MAXIMUM_WORD_LENGTH letters per word
    // * Cannot select a letter further out than the previously selected letter
    private function can_select_letter(l: Letter) {
      // Handy little alias
      var sl = _selected_letters;

      // Letters revealed solely as "will drop soon" can't be used
      if (l.letter_type == Letter.TYPE_NOT_IN_GAME) { return; }

      // If we have no letters, the rest of these checks are unnecessary
      if (sl.length == 0) {return true;}

      // Are we >= maximum letters?  If so, just bomb out here.
      if (sl.length >= Rules.instance.rule('MAXIMUM_WORD_LENGTH')) {return false;}

      // Get last element, see if it's deeper than the letter we want to set.
      if (sl[sl.length - 1].letter_type > l.letter_type) {return false;}

      // If we made it here, all is well
      return true;
    }
  }
}
