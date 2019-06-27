package run_nerd {
  import flash.events.Event;
  import flash.display.Sprite;
  import flash.display.MovieClip;
  import flash.filters.ColorMatrixFilter;
  import flash.text.*;
  import flash.utils.Dictionary;
  import flash.display.BitmapData;
  import flash.display.Bitmap;
  import flash.geom.Matrix;
  import flash.events.Event;
  import flash.events.MouseEvent;

  import generic_code.NumberHelper;
  import run_nerd.Rules;

  // The base letter object - just needs to know its current position and letter
  // to be able to dynamically calculate scoring and such.  Also must
  // (obviously) know its state - used or not
  public class Letter extends MovieClip {
    // Letter type
    public static const TYPE_OUTER  = 0;
    public static const TYPE_MIDDLE = 1;
    public static const TYPE_CENTER = 2;
    public static const TYPE_NOT_IN_GAME = 3;

    public static const WIDTH = 72;
    public static const HEIGHT = 72;

    // Bonus types
    public static const  BONUS_NONE       = 0;
    public static const  BONUS_WORD       = 1;
    public static const  BONUS_SUPER_WORD = 2;

    public static const BONUS_ALPHA_MAX   = 1.00;         // Point at which alpha starts to move back down
    public static const BONUS_ALPHA_MIN   = 0.25;         // Minimum alpha - animation "ends" for a while
    public static const BONUS_ALPHA_MOVE  = 0.05;         // Speed at which alpha moves
    public static const BONUS_ALPHA_PAUSE = 120;          // Frames after alpha hits min before we start alpha animation again

    // Arrays of various letter bitmaps - these are objects that merely consist of the following keys:
    // 'normal': the default button image; 'over': the image to display on mouse over; 'depressed': the
    // image used when clicked (and "in use")
    private static var LETTER_BITMAPS:Array = [];

    // Color matrices for outer/middle/center hue changes
    private static var TEXT_COLORS:Object = {};
    TEXT_COLORS[TYPE_OUTER] = 0xFFFFFF;
    TEXT_COLORS[TYPE_MIDDLE] = 0xFFFF00;
    TEXT_COLORS[TYPE_CENTER] = 0x88FF00;

    // Decoration frames' scores - hard-coded because it's just way easier.  We have a total of
    // nine frames to represent various values of tiles.  "frame" tells us which frame to show
    // on the decoration object (LetterValues), "value" is the value in points (* SCORE_REF),
    private static const DECORATIONS: Array = [
      {frame: 2,  value: 1},
      {frame: 3,  value: 2},
      {frame: 4,  value: 3},
      {frame: 5,  value: 5},
      {frame: 6,  value: 8},
      {frame: 7,  value: 11},
      {frame: 8,  value: 15},
      {frame: 9,  value: 20},
      {frame: 10, value: 25}
    ];

    // Filter for buttons that are unable to be used
    private static var INACTIVE_FILTER = new ColorMatrixFilter([
      0.25, 0.25, 0.25, 0,    0,
      0.25, 0.25, 0.25, 0,    0,
      0.25, 0.25, 0.25, 0,    0,
      0,    0,    0,    1,    0
    ]);

    private static var DEPRESSED_FILTER = new ColorMatrixFilter([
      0.50, 0.25, 0.25, 0,    0,
      0.25, 0.25, 0.25, 0,    0,
      0.25, 0.25, 0.25, 0,    0,
      0,    0,    0,    1,    0
    ]);

    // Font data that all letters will need to use
    private static var letter_format:TextFormat = new TextFormat();
    letter_format.color = 0xFFFFFF;
    letter_format.size  = 48;
    letter_format.font  = "Icicle Country 2";
    letter_format.align = "center";
    private static var letter_offset_x = 0;
    private static var letter_offset_y = -3;
    private static var decoration_offset_x = 65;
    private static var decoration_offset_y = 65;

    private static var tile_offset_x, tile_offset_y;

    // Current bonus tiles
    private static var _bonus_tiles: Object = {};

    private var _letter_type;
    private var _letter;
    private var _bonus_type;
    private var _score:Number;
    private var _speed:Number;
    private var _row:int, _col:int;
    private var _goal_y:int;
    private var _is_used:Boolean, _is_hovered:Boolean;
    private static var _stage_width:int, _stage_height:int;

    private var letter_text:TextField, decoration:LetterValues, bonus_animation:MovieClip;
    private var bonus_alpha_movement, bonus_alpha_pause:Number;
    private var _up_bmp:BitmapData, _down_bmp:BitmapData, _over_bmp:BitmapData, _current_bmp:Bitmap;

    // accessors
    public function get letter_type()   {return _letter_type;}
    public function get bonus_type()    {return _bonus_type;}
    public function get letter()        {return _letter;}
    public function get is_used()       {return _is_used;}
    public function get row()           {return _row;}
    public function get col()           {return _col;}

    // See private method "make_bonus_type" below
    public function is_bonus_word_tile()          { return (BONUS_WORD == _bonus_type); }
    public function make_bonus_word_tile()        { make_bonus_type(BONUS_WORD); }
    public function is_bonus_super_word_tile()    { return (BONUS_SUPER_WORD == _bonus_type); }
    public function make_bonus_super_word_tile()  { make_bonus_type(BONUS_SUPER_WORD); }

    // Add images to the letter bitmaps array
    public static function create_letter_images() {
      var source_bmp:Bitmap = new Bitmap(new LetterSlices(0,0));
      var matrix:Matrix;

      // Types of row in order of how they'll be in the png
      var row_types:Array = ['up', 'over', 'down'];

      // Figure out number of letters by dividing width
      var cols:int = source_bmp.width / WIDTH;

      for (var c = 0; c < cols; c++) {
        var tx = c * -WIDTH;
        var obj = {};
        LETTER_BITMAPS.push(obj);
        for (var r = 0; r < row_types.length; r++) {
          var ty = r * -HEIGHT;
          matrix = source_bmp.transform.matrix;
          matrix.translate(tx, ty);
          var bmd:BitmapData = new BitmapData(WIDTH, HEIGHT);
          bmd.draw(source_bmp, matrix);
          obj[row_types[r]] = bmd;
        }
      }
    }

    // Which decoration frame number do we use for a given score?
    private static function decoration_from_score(score: Number) {
      var decoration = DECORATIONS[0];

      // Find the highest scoring decoration whose value <= our score
      DECORATIONS.forEach(function(dec) {
        if (dec['value'] <= score && dec['value'] > decoration['value']) { decoration = dec }
      });

      if (null != decoration) {return decoration;}

      // If this happens, I have no idea what to do here :P
      trace('ERROR - decoration_from_score for ' + score.toString() + ' didn\'t find anything!');
      return null;
    }

    // For the given letter type, returns number in the game
    public static function bonus_tiles(type:int) {
      return _bonus_tiles[type];
    }

    // Tile value is based on which tile decoration our score gives us
    public function get tile_value() {
      return decoration_from_score(_score)['value'] * Rules.instance.rule('SCORE_REF');
    };

    // Sets up defaults
    public function Letter(col:int, row:int, letter, stage) {
      super();

      if (LETTER_BITMAPS.length == 0) { create_letter_images(); }

      _speed = 0;
      _letter = letter;
      _bonus_type = BONUS_NONE;
      _is_used = false;
      stage.addChild(this);

      var s = new Sprite;
      s.graphics.beginFill(0xCCFF00);
      s.graphics.drawRect(0, 0, WIDTH, HEIGHT);
      addChild(s);
      hitArea = s;

      // Set up letter tile image data
      var bitmap_index:int = Math.random() * (LETTER_BITMAPS.length - 1);
      _up_bmp       = LETTER_BITMAPS[bitmap_index]['up'];
      _down_bmp     = LETTER_BITMAPS[bitmap_index]['down'];
      _over_bmp     = LETTER_BITMAPS[bitmap_index]['over'];

      build_children();
      init_position(col, row);

      addEventListener(MouseEvent.ROLL_OUT, mouse_out);
      addEventListener(MouseEvent.ROLL_OVER, mouse_over);
    }

    // Easy way to figure out if a letter can be made into a bonus letter
    public function can_make_bonus_type(type:int, debug:Boolean = false) {
      var error_format = 'Cannot set a bonus type on letter ' + _col + ','
            + _row + ': %1';
      var errors:Array = new Array();

      if (_bonus_type != BONUS_NONE) {
        errors.push('bonus type is already set to' + _bonus_type.toString());
      }

      if (Letter.TYPE_NOT_IN_GAME == _letter_type) {
        errors.push('letter is not in play');
      }

      if (_is_used) {
        errors.push('letter is already in use');
      }

      if (errors.length > 0) {
        if (debug) { trace(error_format.replace('%1', errors.join(', ')) ) };
        return false;
      }

      return true;
    }

    // Does the actual work of setting bonus type (if allowed), adding animation, etc
    public function make_bonus_type(type) {
      if (false == can_make_bonus_type(type, true)) { return; }

      switch(type) {
        case BONUS_WORD:
          bonus_animation = new LetterBonus_Word;
          break;

        case BONUS_SUPER_WORD:
          bonus_animation = new LetterBonus2_Word;
          break;
      }

      _bonus_type = type;
      _bonus_tiles[_bonus_type]++;
      bonus_animation.x = 0;
      bonus_animation.y = 0;
      bonus_animation.gotoAndStop(1);
      bonus_animation.alpha = BONUS_ALPHA_MAX;
      bonus_alpha_movement = -BONUS_ALPHA_MOVE;
      this.parent.addChild(bonus_animation);
    }

    // Simply use or unuse a letter.  It's up to the caller to determine if this should be allowed.
    public function toggle_button(on:Boolean) {
      _is_used = on;
      reset_filters();
    }

    // Mouse is over us - use _over_bmp
    public function mouse_over(e:MouseEvent) {
      _is_hovered = true;
      reset_filters();
    }

    public function mouse_out(e:MouseEvent) {
      _is_hovered = false;
      reset_filters();
    }

    // Sets our column and row values
    private function init_position(col:int, row:int) {
      _col = col;

      x = tile_offset_x + col * Letter.WIDTH;
      y = -Letter.HEIGHT;

      set_row(row);
    }

    // All the magic we need when setting a given row lives here: figures out letter type, resets filters,
    // and resets score
    private function set_row(row:int) {
      _row = row;
      _goal_y = tile_offset_y + _row * Letter.HEIGHT;

      // Figure out button type
      if (row < 0) {
        _letter_type = Letter.TYPE_NOT_IN_GAME;
        _goal_y -= 8;
      }
      else if (4 == row || 4 == _col || 0 == row || 0 == _col) {
        _letter_type = Letter.TYPE_OUTER;
      }
      else if (2 == row && 2 == _col) {
        _letter_type = Letter.TYPE_CENTER;
      }
      else {
        _letter_type = Letter.TYPE_MIDDLE;
      }
      compute_score(0, 0);
      reset_filters();
    }

    // Ashes, ashes, we all fall down
    public function drop_row() {
      set_row(_row + 1);
    }

    // Set up all defaults, kids, because it's a new game!
    public static function initialize(options) {
      tile_offset_x = options['tile_offset_x'];
      tile_offset_y = options['tile_offset_y'];
      _stage_width  = options['stage_width'];
      _stage_height = options['stage_height'];

      _bonus_tiles[BONUS_WORD]        = 0;
      _bonus_tiles[BONUS_SUPER_WORD]  = 0;
    }

    // Set up our "child" objects - we can't seem to actually attach them to the Letter instance, so we sort of sync
    // them with its position instead.
    public function build_children() {
      // Default blank image
      _current_bmp = new Bitmap(_up_bmp);
      addChild(_current_bmp);

      // Letter itself
      letter_text = new TextField();
      letter_text.width = this.width;
      letter_text.defaultTextFormat = letter_format;
      letter_text.embedFonts = true;
      letter_text.mouseEnabled = false;
      letter_text.x = letter_offset_x;
      letter_text.y = letter_offset_y;
      addChild(letter_text);

      // Indicator of worth
      decoration = new LetterValues;
      decoration.width = 10;
      decoration.height = 10;
      decoration.x = decoration_offset_x;
      decoration.y = decoration_offset_y;
      addChild(decoration);
    }

    // We dun got killed!  Remove us and children from stage
    public function destroy() {
      this.parent.removeChild(this);
      removeChild(decoration);
      removeChild(letter_text);
      if (BONUS_NONE != _bonus_type) {_bonus_tiles[_bonus_type]--;}
      if (bonus_animation) {bonus_animation.parent.removeChild(bonus_animation);}
      decoration = null;
      letter_text = null;
      bonus_animation = null;
    }

    // For now, just animates us falling down if necessary.  Our "child" objects must follow or things look pretty
    // stupid.
    public function on_enter_frame(e:Event) {
      y += _speed;

      if (y < _goal_y) {
        _speed += 1;
        // Terminal velocity!!
        if (_speed > 20) {_speed = 20;}
      }
      else {
        y = _goal_y;
        // bounce if we're fast enough for it to show
        // TODO: Make a noise here!
        if (_speed > 2) _speed = -(_speed / 3);
        else _speed = 0;
      }

      // Check for bonus animation in need of animating
      if (bonus_animation) {
        bonus_animation_frame(e);
      }
    }

    private function bonus_animation_frame(e:Event) {
      // No alpha animation until we finish the zoom-in animation
      if (bonus_animation.currentFrame != bonus_animation.totalFrames) {

        // Advance one frame, re-center on letter
        bonus_animation.gotoAndStop(bonus_animation.currentFrame + 1);
        bonus_animation.x = (this.x + this.width / 2) - bonus_animation.width / 2;
        bonus_animation.y = (this.y + this.height / 2) - bonus_animation.height / 2 - 17.15;

        // If we're done, attach to the letter instead of the stage
        if (bonus_animation.currentFrame == bonus_animation.totalFrames) {
          this.parent.removeChild(bonus_animation);
          this.addChild(bonus_animation);
          bonus_animation.x = 0;
          bonus_animation.y = 0;
          // TODO: Make a sound
        }
        return;
      }

      // If we have a pause, we don't animate alpha until it's done
      if (bonus_alpha_pause > 0) {
        bonus_alpha_pause--;
        return;
      }

      bonus_animation.alpha += bonus_alpha_movement;
      if (bonus_animation.alpha >= BONUS_ALPHA_MAX && bonus_alpha_movement > 0) {
        bonus_alpha_movement = -BONUS_ALPHA_MOVE;
      }
      else if (bonus_animation.alpha <= BONUS_ALPHA_MIN && bonus_alpha_movement < 0) {
        bonus_alpha_movement = BONUS_ALPHA_MOVE;
        // Actual delay is 0.75x to 1.25x
        bonus_alpha_pause = BONUS_ALPHA_PAUSE * Math.random() * (75, 125) / 100;
      }
    }

    // Build labels based on current value of letter and score
    public function update_labels() {
      letter_text.text = _letter;
      if (TYPE_NOT_IN_GAME == _letter_type) {
        decoration.gotoAndStop(0);
      }
      else {
        decoration.gotoAndStop(decoration_from_score(_score)['frame']);
      }
    }

    // Value of this letter based on base scores and our position
    // TODO: Put this in rules json!
    public function base_score() {
      // Blank tiles (in case we do wild cards)
      if ('' == _letter || ' ' == _letter) {return 0;}
      var multiplier;
      switch(_letter_type) {
        case TYPE_NOT_IN_GAME:
          multiplier = 0;
          break;
        case TYPE_OUTER:
          multiplier = 1;
          break;
        case TYPE_MIDDLE:
          multiplier = 1.50;
          break;
        case TYPE_CENTER:
          multiplier = 2;
          break;
      }
      var val = Rules.instance.rule('LETTER_POINTS')[_letter] * multiplier;
      return val;
    }

    // Based on our base letter, position in the grid (outer, middle, center),
    // and number of letters already chosen, calculate score.  Base score *
    // positional multiplier + boost for letters selected before this one.
    public function compute_score(outer_selected, middle_selected) {
      // Get the base score
      _score = base_score();

      // Now compute boost - you only get the boost for letters further outside
      // than this one.
      var x;
      if (_letter_type == TYPE_MIDDLE) {
        for (x = 0; x < outer_selected; x++) {
          increase_score();
        }
      }
      else if (_letter_type == TYPE_CENTER) {
        for (x = 0; x < outer_selected + middle_selected; x++) {
          increase_score();
        }
      }

      update_labels();
    }

    // Increases score for prior letters in outer rings being clicked
    // TODO: Put in rules.json!
    private function increase_score() {
      // Increase by 1/2x-3x points - this means even a letter worth nothing goes up
      var increase = Math.max(Math.min(_score * 0.333, 3), 0.50);
      _score += increase;
    }

    // Sets up default filters for color and down vs. up state - shouldn't be called too often as I don't know the
    // performance impact of changing bitmapData....
    private function reset_filters() {
      letter_text.textColor = TEXT_COLORS[_letter_type];

      // Hack the used buttons to permanently show the down state
      if (_is_used) {
        _current_bmp.filters = [DEPRESSED_FILTER];
        this.enabled = false;
        _current_bmp.bitmapData = _down_bmp;
        return;
      }

      // Letters not in the game are disabled and greyed out
      if (_letter_type == TYPE_NOT_IN_GAME) {
        _current_bmp.bitmapData = _up_bmp;
        _current_bmp.filters = [INACTIVE_FILTER];
        this.enabled = false;
        return;
      }

      // Only check hover if the button can be clicked
      _current_bmp.bitmapData = _is_hovered ? _over_bmp : _up_bmp;
      _current_bmp.filters = [];
      this.enabled = true;
    }
  }
}
