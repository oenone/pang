--
-- Copyright (c) 2011 Julian Leyh <julian@vgai.de>
--
-- Permission to use, copy, modify, and distribute this software for any
-- purpose with or without fee is hereby granted, provided that the above
-- copyright notice and this permission notice appear in all copies.
--
-- THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
-- WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
-- ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
-- WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
-- ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
-- OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
--

with Lumen.Events.Animate;
with Lumen.GL;

package Game is
   use Lumen;

   type Format is record
      Width     : GL.SizeI;
      Height    : GL.SizeI;
      Framerate : Events.Animate.Frame_Count;
   end record;

   type Ball is record
      Xpos, Ypos : Float; -- current position
      Xspeed     : Float;
      Yspeed     : Float;
      Size       : Float;
   end record;

   type Paddle is record
      width    : Float; -- width
      height   : Float; -- height
      position : Float; -- current position
   end record;

   type GameState is
     (Title, -- Display title screen, change to ingame/exiting
      Ingame, -- process game keys and pause keys
      -- update ball position
      -- update paddles position
      -- draw everything
      Paused, -- key back to Ingame
      Game_Over, -- key back to Title
      Exiting); -- Exit game

   procedure Run_Game (Screen_Format : Format);

   type GameData is record
      The_Ball      : Ball;
      Upper_Paddle  : Paddle;
      Lower_Paddle  : Paddle;
      Screen_Format : Format;
      The_State     : GameState;
   end record;

   Error_Loading_Image : exception;

end Game;
