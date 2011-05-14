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

with Ada.Characters.Latin_1;
with Lumen.Window;
with Lumen.Events.Keys;
with Lumen.Image;
with System;

package body Game is

   The_Window    : Window.Handle;
   Data          : GameData;
   TitleScreen   : GL.UInt;
   Paddle_Height : constant Float := 20.0;
   type Player_Type is (Upper_Player, Lower_Player);
   Winner          : Player_Type;
   Gameover_Screen : array (Player_Type) of GL.UInt;

   procedure Reset_Game_Data is
   begin
      Data.The_Ball.Xpos         := Float (Data.Screen_Format.Width) / 2.0;
      Data.The_Ball.Ypos         := Float (Data.Screen_Format.Height) / 2.0;
      Data.The_Ball.Xspeed       := 100.0;
      Data.The_Ball.Yspeed       := 100.0;
      Data.The_Ball.Size         := 10.0;
      Data.Upper_Paddle.width    := 200.0;
      Data.Lower_Paddle.width    := 200.0;
      Data.Upper_Paddle.height   := 15.0;
      Data.Lower_Paddle.height   := 15.0;
      Data.Upper_Paddle.position := Float (Data.Screen_Format.Width) / 2.0 -
                                    100.0;
      Data.Lower_Paddle.position := Float (Data.Screen_Format.Width) / 2.0 -
                                    100.0;
   end Reset_Game_Data;

   procedure Change_State (To : GameState) is
   begin
      case To is
         when Ingame =>
            if Data.The_State /= Paused then
               Reset_Game_Data;
            end if;
         when others =>
            null;
      end case;
      Data.The_State := To;
   end Change_State;

   -- simply exit this program
   procedure Quit_Handler (Event : Lumen.Events.Event_Data) is
      pragma Unreferenced (Event);
   begin
      Lumen.Events.End_Events (The_Window);
   end Quit_Handler;

   -- Resize the scene
   procedure Resize_Scene (Width, Height : Natural) is
   begin
      -- reset current viewport
      GL.Viewport (0, 0, Width, Height);

      -- select projection matrix and reset it
      GL.MatrixMode (GL.GL_PROJECTION);
      GL.LoadIdentity;

      -- 2D orthogonal perspective
      GL.Ortho
        (Left     => 0.0,
         Right    => Long_Float (Width),
         Bottom   => 0.0,
         Top      => Long_Float (Height),
         Near_Val => -1.0,
         Far_Val  => 1.0);

      -- select modelview matrix
      GL.MatrixMode (GL.GL_MODELVIEW);
   end Resize_Scene;

   procedure Load_GL_Textures is
      IP              : GL.Pointer;
      Title_Image     : constant Lumen.Image.Descriptor :=
         Image.From_File ("title.bmp");
      Up_Image        : constant Lumen.Image.Descriptor :=
         Image.From_File ("up.bmp");
      Down_Image      : constant Lumen.Image.Descriptor :=
         Image.From_File ("dn.bmp");
      Up_Down_Pointer : constant System.Address         :=
         Gameover_Screen'Address;
      Texture_Pointer : constant System.Address         :=
         TitleScreen'Address;
   begin
      -- create
      GL.GenTextures (1, Texture_Pointer);

      -- Bind texture operations to the newly-created texture name
      GL.BindTexture (GL.GL_TEXTURE_2D, TitleScreen);
      GL.TexParameter
        (GL.GL_TEXTURE_2D,
         GL.GL_TEXTURE_MIN_FILTER,
         GL.GL_NEAREST);
      GL.TexParameter
        (GL.GL_TEXTURE_2D,
         GL.GL_TEXTURE_MAG_FILTER,
         GL.GL_NEAREST);
      IP := Title_Image.Values.all'Address;
      GL.TexImage
        (GL.GL_TEXTURE_2D, 0, GL.GL_RGB,
         Title_Image.Width, Title_Image.Height,
         0, GL.GL_RGBA, GL.GL_UNSIGNED_BYTE, IP);

      -- create
      GL.GenTextures (2, Up_Down_Pointer);

      GL.BindTexture (GL.GL_TEXTURE_2D, Gameover_Screen (Upper_Player));
      GL.TexParameter
        (GL.GL_TEXTURE_2D,
         GL.GL_TEXTURE_MIN_FILTER,
         GL.GL_NEAREST);
      GL.TexParameter
        (GL.GL_TEXTURE_2D,
         GL.GL_TEXTURE_MAG_FILTER,
         GL.GL_NEAREST);
      IP := Up_Image.Values.all'Address;
      GL.TexImage
        (GL.GL_TEXTURE_2D, 0, GL.GL_RGB,
         Up_Image.Width, Up_Image.Height,
         0, GL.GL_RGBA, GL.GL_UNSIGNED_BYTE, IP);

      GL.BindTexture (GL.GL_TEXTURE_2D, Gameover_Screen (Lower_Player));
      GL.TexParameter
        (GL.GL_TEXTURE_2D,
         GL.GL_TEXTURE_MIN_FILTER,
         GL.GL_NEAREST);
      GL.TexParameter
        (GL.GL_TEXTURE_2D,
         GL.GL_TEXTURE_MAG_FILTER,
         GL.GL_NEAREST);
      IP := Down_Image.Values.all'Address;
      GL.TexImage
        (GL.GL_TEXTURE_2D, 0, GL.GL_RGB,
         Down_Image.Width, Down_Image.Height,
         0, GL.GL_RGBA, GL.GL_UNSIGNED_BYTE, IP);
   end Load_GL_Textures;

   procedure Init_GL is
   begin
      -- load textures
      Load_GL_Textures;
      -- enable texture mapping
      GL.Enable (GL.GL_TEXTURE_2D);

      -- smooth shading
      GL.ShadeModel (GL.GL_SMOOTH);

      -- black background
      GL.ClearColor (0.0, 0.0, 0.0, 0.5);

      -- depth buffer setup
      GL.ClearDepth (1.0);
      -- enable depth testing
      GL.Enable (GL.GL_DEPTH_TEST);
      -- type of depth test
      GL.DepthFunc (GL.GL_LEQUAL);

      GL.Hint (GL.GL_PERSPECTIVE_CORRECTION_HINT, GL.GL_NICEST);
   end Init_GL;

   -- Resize and Initialize the GL window
   procedure Resize_Handler (Event : Lumen.Events.Event_Data) is
      Height : Natural          := Event.Resize_Data.Height;
      Width  : constant Natural := Event.Resize_Data.Width;
   begin
      -- prevent div by zero
      if Height = 0 then
         Height := 1;
      end if;

      Resize_Scene (Width, Height);
   end Resize_Handler;

   procedure Draw_Ball is
      Offset : constant Float := Data.The_Ball.Size / 2.0;
   begin
      GL.PushMatrix;
      GL.Translate (Data.The_Ball.Xpos, Data.The_Ball.Ypos, 0.0);
      GL.glBegin (GL.GL_QUADS);
      begin
         GL.Vertex (-Offset, Offset, 0.0);
         GL.Vertex (-Offset, -Offset, 0.0);
         GL.Vertex (Offset, -Offset, 0.0);
         GL.Vertex (Offset, Offset, 0.0);
      end;
      GL.glEnd;
      GL.PopMatrix;
   end Draw_Ball;

   procedure Draw_Paddles is
   begin
      -- upper paddle
      GL.PushMatrix;
      GL.Translate
        (Data.Upper_Paddle.position,
         Float (Data.Screen_Format.Height),
         0.0);
      GL.glBegin (GL.GL_QUADS);
      begin
         GL.Vertex (0.0, -Paddle_Height);
         GL.Vertex (Float (0.0), 0.0);
         GL.Vertex (Data.Upper_Paddle.width, 0.0);
         GL.Vertex (Data.Upper_Paddle.width, -Paddle_Height);
      end;
      GL.glEnd;
      GL.PopMatrix;
      -- lower paddle
      GL.PushMatrix;
      GL.Translate (Data.Lower_Paddle.position, 0.0, 0.0);
      GL.glBegin (GL.GL_QUADS);
      begin
         GL.Vertex (0.0, Paddle_Height);
         GL.Vertex (Float (0.0), 0.0);
         GL.Vertex (Data.Lower_Paddle.width, 0.0);
         GL.Vertex (Data.Lower_Paddle.width, Paddle_Height);
      end;
      GL.glEnd;
      GL.PopMatrix;
   end Draw_Paddles;

   procedure Draw_Title is
      use type GL.Bitfield;
   begin
      -- clear the screen and the depth buffer
      GL.Clear (GL.GL_COLOR_BUFFER_BIT or GL.GL_DEPTH_BUFFER_BIT);
      -- reset modelview matrix
      GL.LoadIdentity;
      GL.BindTexture (GL.GL_TEXTURE_2D, TitleScreen);
      GL.glBegin (GL.GL_QUADS);
      begin
         GL.TexCoord (Float (0.0), 1.0);
         GL.Vertex (Float (0.0), 0.0);
         GL.TexCoord (Float (1.0), 1.0);
         GL.Vertex (Float (Data.Screen_Format.Width), 0.0);
         GL.TexCoord (Float (1.0), 0.0);
         GL.Vertex
           (Float (Data.Screen_Format.Width),
            Float (Data.Screen_Format.Height));
         GL.TexCoord (Float (0.0), 0.0);
         GL.Vertex (0.0, Float (Data.Screen_Format.Height));
      end;
      GL.glEnd;
   end Draw_Title;

   procedure Draw_Gameover is
      use type GL.Bitfield;
   begin
      -- clear the screen and the depth buffer
      GL.Clear (GL.GL_COLOR_BUFFER_BIT or GL.GL_DEPTH_BUFFER_BIT);
      -- reset modelview matrix
      GL.LoadIdentity;
      GL.BindTexture (GL.GL_TEXTURE_2D, Gameover_Screen (Winner));
      GL.glBegin (GL.GL_QUADS);
      begin
         GL.TexCoord (Float (0.0), 1.0);
         GL.Vertex (Float (0.0), 0.0);
         GL.TexCoord (Float (1.0), 1.0);
         GL.Vertex (Float (Data.Screen_Format.Width), 0.0);
         GL.TexCoord (Float (1.0), 0.0);
         GL.Vertex
           (Float (Data.Screen_Format.Width),
            Float (Data.Screen_Format.Height));
         GL.TexCoord (Float (0.0), 0.0);
         GL.Vertex (0.0, Float (Data.Screen_Format.Height));
      end;
      GL.glEnd;
   end Draw_Gameover;

   procedure Draw_Game is
      use type GL.Bitfield;
   begin
      -- clear the screen and the depth buffer
      GL.Clear (GL.GL_COLOR_BUFFER_BIT or GL.GL_DEPTH_BUFFER_BIT);
      -- reset modelview matrix
      GL.LoadIdentity;
      -- draw the paddles
      Draw_Paddles;
      -- draw the ball
      Draw_Ball;
   end Draw_Game;

   procedure Draw is
      use type GL.Bitfield;
   begin
      -- draw everything
      case Data.The_State is
         when Title =>
            Draw_Title;
         when Ingame =>
            Draw_Game;
         when Game_Over =>
            Draw_Gameover;
         when others =>
            null;
      end case;
   end Draw;

   procedure Frame_Handler (Frame_Delta : Duration) is
   begin
      -- update positions
      case Data.The_State is
         when Ingame =>
            Data.The_Ball.Xpos := Data.The_Ball.Xpos +
                                  Data.The_Ball.Xspeed * Float (Frame_Delta);
            Data.The_Ball.Ypos := Data.The_Ball.Ypos +
                                  Data.The_Ball.Yspeed * Float (Frame_Delta);
            -- missed paddle?
            if (Data.The_Ball.Ypos < Paddle_Height)
              and then (Data.The_Ball.Xpos < Data.Lower_Paddle.position
                       or else Data.The_Ball.Xpos >
                               (Data.Lower_Paddle.position +
                                Data.Lower_Paddle.width)) then
               Change_State (To => Game_Over);
               Winner := Upper_Player;
            end if;
            if (Data.The_Ball.Ypos >
                Float (Data.Screen_Format.Height) - Paddle_Height)
              and then (Data.The_Ball.Xpos < Data.Upper_Paddle.position
                       or else Data.The_Ball.Xpos >
                               Data.Upper_Paddle.position +
                               Data.Upper_Paddle.width) then
               Change_State (To => Game_Over);
               Winner := Lower_Player;
            end if;

            -- bounce off walls
            if Data.The_Ball.Xpos >
               Float (Data.Screen_Format.Width) - Data.The_Ball.Size then
               Data.The_Ball.Xspeed := -Data.The_Ball.Xspeed;
               Data.The_Ball.Xpos   := Float (Data.Screen_Format.Width) -
                                       Data.The_Ball.Size;
            elsif Data.The_Ball.Xpos < Data.The_Ball.Size then
               Data.The_Ball.Xspeed := -Data.The_Ball.Xspeed;
               Data.The_Ball.Xpos   := Data.The_Ball.Size;
            end if;
            -- bounce off paddles
            if Data.The_Ball.Ypos >
               Float (Data.Screen_Format.Height) - Paddle_Height then
               Data.The_Ball.Yspeed := -Data.The_Ball.Yspeed;
               Data.The_Ball.Ypos   := Float (Data.Screen_Format.Height) -
                                       Paddle_Height;
            elsif Data.The_Ball.Ypos < Paddle_Height then
               Data.The_Ball.Yspeed := -Data.The_Ball.Yspeed;
               Data.The_Ball.Ypos   := Paddle_Height;
            end if;
         when others =>
            null;
      end case;
      Draw;
      Window.Swap (The_Window);
   end Frame_Handler;

   procedure Key_Handler (Event : Lumen.Events.Event_Data) is
      Key_Data : Events.Key_Event_Data renames Event.Key_Data;
   begin
      case Key_Data.Key is
         when Events.Keys.Left =>
            if Data.The_State = Ingame
              and then Data.Lower_Paddle.position >= 10.0 then
               Data.Lower_Paddle.position := Data.Lower_Paddle.position -
                                             10.0;
            end if;
         when Events.Keys.Right =>
            if Data.The_State = Ingame
              and then Data.Lower_Paddle.position <=
                       Float (Data.Screen_Format.Width - 10) -
                       Data.Lower_Paddle.width then
               Data.Lower_Paddle.position := Data.Lower_Paddle.position +
                                             10.0;
            end if;

         when others =>
            if Key_Data.Key =
               Events.To_Symbol (Ada.Characters.Latin_1.ESC) then
               -- Escape: quit
               Change_State (To => Exiting);
               Events.End_Events (The_Window);
            elsif Key_Data.Key =
                  Events.To_Symbol (Ada.Characters.Latin_1.CR) then
               -- return:
               if Data.The_State = Title then
                  Change_State (To => Ingame);
               elsif Data.The_State = Game_Over then
                  Change_State (To => Title);
               end if;
            else
               -- check character code
               declare
                  Key_Char : constant Character :=
                     Events.To_Character (Key_Data.Key);
               begin
                  case Key_Char is
                     when 'p' =>
                        if Data.The_State = Ingame then
                           Change_State (To => Paused);
                        elsif Data.The_State = Paused then
                           Change_State (To => Ingame);
                        end if;
                     when 'a' =>
                        if Data.The_State = Ingame
                          and then Data.Upper_Paddle.position >= 10.0 then
                           Data.Upper_Paddle.position :=
                             Data.Upper_Paddle.position - 10.0;
                        end if;
                     when 'd' =>
                        if Data.The_State = Ingame
                          and then Data.Upper_Paddle.position <=
                                   Float (Data.Screen_Format.Width - 10) -
                                   Data.Upper_Paddle.width then
                           Data.Upper_Paddle.position :=
                             Data.Upper_Paddle.position + 10.0;
                        end if;
                     when others =>
                        null;
                  end case;
               end;
            end if;
      end case;
   exception
      when Events.Not_Character =>
         null;
   end Key_Handler;

   procedure Run_Game (Screen_Format : Format) is
   begin
      -- initialize variables
      Data.Screen_Format := Screen_Format;
      Reset_Game_Data;

      Change_State (To => Title);

      Lumen.Window.Create
        (Win    => The_Window,
         Name   => "pAng",
         Width  => Data.Screen_Format.Width,
         Height => Data.Screen_Format.Height,
         Events => (Lumen.Window.Want_Key_Press => True,
                    Lumen.Window.Want_Exposure  => True,
                    others => False));

      Resize_Scene (Data.Screen_Format.Width, Data.Screen_Format.Height);
      Init_GL;

      Lumen.Events.Animate.Select_Events
        (Win   => The_Window,
         FPS   => Data.Screen_Format.Framerate,
         Frame => Frame_Handler'Unrestricted_Access,
         Calls => (Lumen.Events.Resized      =>
        Resize_Handler'Unrestricted_Access,
                   Lumen.Events.Close_Window =>
        Quit_Handler'Unrestricted_Access,
                   Lumen.Events.Key_Press    =>
        Key_Handler'Unrestricted_Access,
                   others => Lumen.Events.No_Callback));

      Lumen.Window.Destroy_Context (The_Window);
      Lumen.Window.Destroy (The_Window);
   end Run_Game;

end Game;
