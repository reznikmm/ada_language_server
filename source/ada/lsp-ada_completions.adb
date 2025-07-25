------------------------------------------------------------------------------
--                         Language Server Protocol                         --
--                                                                          --
--                     Copyright (C) 2018-2023, AdaCore                     --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.  You should have  received  a copy of the GNU --
-- General  Public  License  distributed  with  this  software;   see  file --
-- COPYING3.  If not, go to http://www.gnu.org/licenses for a complete copy --
-- of the license.                                                          --
------------------------------------------------------------------------------

with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Containers.Hashed_Sets;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;   use Ada.Strings.Unbounded;

with Gnatformat;
with Gnatformat.Formatting;
with VSS.Characters.Latin;
with VSS.Regular_Expressions;
with VSS.Strings;              use VSS.Strings;
with VSS.Strings.Conversions;
with VSS.Strings.Cursors.Iterators.Characters;
with VSS.Strings.Cursors.Markers;
with VSS.Strings.Hash;
with VSS.String_Vectors;
with VSS.Transformers.Casing;

with LSP.Ada_Configurations;
with LSP.Ada_Contexts;
with LSP.Ada_Documents;
with LSP.Enumerations;
with LSP.Utils;

with Pp.Scanner;

package body LSP.Ada_Completions is
   pragma Warnings (Off);

   package Encoding_Maps is new Ada.Containers.Indefinite_Hashed_Maps
     (Key_Type        => VSS.Strings.Virtual_String,
      Element_Type    => VSS.Strings.Virtual_String,
      Hash            => VSS.Strings.Hash,
      Equivalent_Keys => VSS.Strings."=");

   ------------------
   -- Is_End_Token --
   ------------------

   function Is_End_Token
     (Token : Libadalang.Common.Token_Reference) return Boolean
   is
      use Libadalang.Common;
   begin
      if Token = No_Token then
         return False;
      end if;

      declare
         End_Token : constant Libadalang.Common.Token_Data_Type :=
           Libadalang.Common.Data (Token);

         Token_Kind : constant Libadalang.Common.Token_Kind :=
           Libadalang.Common.Kind (End_Token);
      begin
         return Token_Kind = Libadalang.Common.Ada_End;
      end;
   end Is_End_Token;

   ------------------------
   -- Is_Full_Sloc_Equal --
   ------------------------

   function Is_Full_Sloc_Equal
     (Left, Right : Libadalang.Analysis.Defining_Name) return Boolean
   is
      use type Libadalang.Analysis.Analysis_Unit;
      use type Langkit_Support.Slocs.Source_Location_Range;
   begin
      return Left.Sloc_Range = Right.Sloc_Range
        and then Left.Unit = Right.Unit;
   end Is_Full_Sloc_Equal;

   -----------------------
   -- Skip_Dotted_Names --
   -----------------------

   function Skip_Dotted_Names
     (Node : Libadalang.Analysis.Ada_Node)
      return Libadalang.Analysis.Ada_Node
   is
      use Libadalang.Common;
      Parent : Libadalang.Analysis.Ada_Node := Node;
   begin
      while not Parent.Is_Null
        and then Parent.Kind = Libadalang.Common.Ada_Dotted_Name
      loop
         Parent := Parent.Parent;
      end loop;

      return Parent;
   end Skip_Dotted_Names;

   -----------------------
   -- Write_Completions --
   -----------------------

   procedure Write_Completions
     (Handler                  : in out LSP.Ada_Handlers.Message_Handler;
      Context                  : LSP.Ada_Contexts.Context;
      Document                 : LSP.Ada_Documents.Document;
      Sloc                     : Langkit_Support.Slocs.Source_Location;
      Token                    : Libadalang.Common.Token_Reference;
      Node                     : Libadalang.Analysis.Ada_Node;
      Names                    : Completion_Maps.Map;
      Named_Notation_Threshold : Natural;
      Compute_Doc_And_Details  : Boolean;
      Result                   : in out LSP.Structures.CompletionItem_Vector)
   is
      package String_Sets is new Ada.Containers.Hashed_Sets
        (VSS.Strings.Virtual_String,
         VSS.Strings.Hash,
         VSS.Strings."=",
         VSS.Strings."=");

      Seen   : String_Sets.Set;
      --  Set of found visible names in canonical form
      Length : constant Natural := Natural (Names.Length);
      From   : constant Langkit_Support.Slocs.Source_Location :=
        Langkit_Support.Slocs.Start_Sloc
          (Libadalang.Common.Sloc_Range (Libadalang.Common.Data (Token)));

   begin

      --  Write Result in two pases. Firstly append all visible names and
      --  populate Seen set. Then append invisible names not in Seen.

      for Visible in reverse Boolean loop  --  Phase: True then False
         for Cursor in Names.Iterate loop
            declare
               Append    : Boolean := False;
               Info      : constant Name_Information := Names (Cursor);
               Name      : constant Libadalang.Analysis.Defining_Name :=
                 Completion_Maps.Key (Cursor);
               Selector  : constant Libadalang.Analysis.Name :=
                 Name.P_Relative_Name;
               Label     : VSS.Strings.Virtual_String;
               Canonical : VSS.Strings.Virtual_String;
            begin
               if Visible and Info.Is_Visible then
                  Label := VSS.Strings.To_Virtual_String (Selector.Text);
                  Canonical := LSP.Utils.Canonicalize (Label);
                  Seen.Include (Canonical);
                  Append := True;
               elsif not Visible and not Info.Is_Visible then
                  --  Append invisible name on if no such visible name found
                  Label := VSS.Strings.To_Virtual_String (Selector.Text);
                  Canonical := LSP.Utils.Canonicalize (Label);
                  Append := not Seen.Contains (Canonical);
               end if;

               if Append then
                  Result.Append
                    (Document.Compute_Completion_Item
                       (Handler                  => Handler,
                        Context                  => Context,
                        Sloc                     => Sloc,
                        From                     => From,
                        Node                     => Node,
                        BD                       => Name.P_Basic_Decl,
                        Label                    => Label,
                        Use_Snippets             => Info.Use_Snippets,
                        Compute_Doc_And_Details  => Compute_Doc_And_Details,
                        Named_Notation_Threshold => Named_Notation_Threshold,
                        Is_Dot_Call              => Info.Is_Dot_Call,
                        Is_Visible               => Info.Is_Visible,
                        Pos                      => Info.Pos,
                        Weight                   => Info.Weight,
                        Completions_Count        => Length));
               end if;
            end;
         end loop;
      end loop;
   end Write_Completions;

   --------------------------
   -- Pretty_Print_Snippet --
   --------------------------

   procedure Pretty_Print_Snippet
     (Context : LSP.Ada_Contexts.Context;
      Prefix  : VSS.Strings.Virtual_String;
      Offset  : Natural;
      Span    : LSP.Structures.A_Range;
      Rule    : Libadalang.Common.Grammar_Rule;
      Result  : in out LSP.Structures.CompletionItem)
   is
      use LSP.Ada_Contexts;

      Encoding : Encoding_Maps.Map;
      --  Map of Snippet fake name to snippet:
      --  {"foobar_1" : "$1", "foobar_2" : "${2: Integer}"}
      --  $0 will not be replaced

      function Encode_String (S : Virtual_String) return Virtual_String;
      --  Create pseudo code for the snippet

      function Decode_String (S : Virtual_String) return Virtual_String;
      --  Recreate the snippet via the pseudo code

      function Snippet_Placeholder (S : Virtual_String) return Virtual_String
      is ("foobar_" & S);
      --  Generate a fake entity for a snippet (S is the index of the snippet)
      --  The length of the placeholder will affect where the strings is cut
      --  to avoid exceeding line length => 8/9 characters seems to be
      --  reasonable (most of the time a placeholder is replacing the
      --  parameter type's name)

      function Find_Next_Placeholder
        (S     : Virtual_String;
         Start : VSS.Strings.Cursors.Iterators.Characters.
           Character_Iterator'Class)
         return VSS.Regular_Expressions.Regular_Expression_Match;
      --  Find the next placeholder starting from Start in S

      function Post_Pretty_Print (S : Virtual_String) return Virtual_String;
      --  Indent the block using the initial location and add back $0 (it has
      --  been removed to not generate invalid pseudo code)

      -------------------
      -- Encode_String --
      -------------------

      function Encode_String (S : Virtual_String) return Virtual_String
      is
         Res           : Virtual_String;
         Start_Encoded : VSS.Strings.Cursors.Markers.Character_Marker;
         Search_Index  : Boolean := False;
         Encoded_Index : Virtual_String;
         In_Snippet    : Boolean := False;

         procedure Add_Placeholder
           (Cursor : VSS.Strings.Cursors.Abstract_Cursor'Class);

         ---------------------
         -- Add_Placeholder --
         ---------------------

         procedure Add_Placeholder
           (Cursor : VSS.Strings.Cursors.Abstract_Cursor'Class)
         is
            Placeholder : constant Virtual_String :=
              Snippet_Placeholder (Encoded_Index);
         begin
            if not Encoded_Index.Is_Empty then
               Encoding.Insert
                 (Placeholder,
                  S.Slice (S.At_Character (Start_Encoded), Cursor));
               Append (Res, Placeholder);
               Encoded_Index.Clear;
            end if;
         end Add_Placeholder;

         I     : VSS.Strings.Cursors.Iterators.Characters.
           Character_Iterator := S.At_First_Character;
         Dummy : Boolean;
      begin
         while I.Has_Element loop
            case I.Element is
               when '$' =>
                  Search_Index := True;
                  Start_Encoded := I.Marker;
                  Encoded_Index.Clear;
               when '{' =>
                  In_Snippet := True;
               when '}' =>
                  Add_Placeholder (I);
                  In_Snippet := False;
                  Search_Index := False;
               when '0' .. '9' =>
                  if Search_Index then
                     Append (Encoded_Index, I.Element);
                  elsif not In_Snippet then
                     Append (Res, I.Element);
                  end if;
               when others =>
                  Search_Index := False;
                  if not In_Snippet then
                     Add_Placeholder (I);
                     Append (Res, I.Element);
                  end if;
            end case;
            Dummy := I.Forward;
         end loop;

         --  Do nothing for $0 which will be removed at the end

         return Res;
      end Encode_String;

      -------------------
      -- Decode_String --
      -------------------

      function Decode_String (S : Virtual_String) return Virtual_String
      is
         use type VSS.Characters.Virtual_Character;

         Res   : Virtual_String;
         U     : Virtual_String := S;
         Dummy : Boolean;
      begin
         --  Remove the extra whitespace at the start
         while U.At_First_Character.Element = VSS.Characters.Latin.Space loop
            U.Delete (U.At_First_Character, U.At_First_Character);
         end loop;

         declare
            Iterator : VSS.Strings.Cursors.Iterators.Characters.
              Character_Iterator := U.At_First_Character;
         begin
            loop
               declare
                  Match : constant VSS.Regular_Expressions.
                    Regular_Expression_Match :=
                      Find_Next_Placeholder (U, Iterator);
               begin
                  exit when not Match.Has_Match;
                  declare
                     Pos : VSS.Strings.Cursors.Iterators.Characters.
                       Character_Iterator := U.At_Character
                         (Match.First_Marker);
                  begin
                     Dummy := Pos.Backward;
                     Append (Res, U.Slice (Iterator, Pos));
                  end;
                  Append
                    (Res,
                     Encoding
                       (VSS.Transformers.Casing.To_Lowercase.Transform
                            (Match.Captured)));
                  Iterator.Set_At (Match.Last_Marker);
                  Dummy := Iterator.Forward;
               end;
            end loop;

            Append (Res, U.Slice (Iterator, U.At_Last_Character));
         end;

         return Res;
      end Decode_String;

      ---------------------------
      -- Find_Next_Placeholder --
      ---------------------------

      function Find_Next_Placeholder
        (S     : Virtual_String;
         Start : VSS.Strings.Cursors.Iterators.Characters.
           Character_Iterator'Class)
         return VSS.Regular_Expressions.Regular_Expression_Match
      is
         Placeholder_Regexp : constant VSS.Regular_Expressions.
           Regular_Expression := VSS.Regular_Expressions.To_Regular_Expression
             ("FooBar_[0-9]+",
              Options => [VSS.Regular_Expressions.Case_Insensitive => True,
                          others => False]);
      begin
         return Placeholder_Regexp.Match (S, Start);
      end Find_Next_Placeholder;

      -----------------------
      -- Post_Pretty_Print --
      -----------------------

      function Post_Pretty_Print (S : Virtual_String) return Virtual_String
      is
         Res : Virtual_String;
      begin
         --  Remove this condition when V725-006 is fixed
         if Ends_With (S, New_Line_Function) then
            declare
               C : VSS.Strings.Cursors.Iterators.Characters.
                 Character_Iterator := S.At_Last_Character;
               Dummy : Boolean;
            begin
               Dummy := C.Backward;
               Res := Slice (S, S.At_First_Character, C);
            end;
         else
            Res := S;
         end if;

         --  Add the offset for each lines except the first one which is
         --  already aligned with the cursor
         declare
            Lines : constant VSS.String_Vectors.Virtual_String_Vector :=
              Res.Split_Lines
                (Terminators     =>
                   (VSS.Strings.CR | VSS.Strings.CRLF | VSS.Strings.LF => True,
                    others => False),
                 Keep_Terminator => True);
            First : Boolean := True;
         begin
            Res := Empty_Virtual_String;
            for Line of Lines loop
               if First then
                  First := False;
                  Res.Append (Line);
               else
                  Res.Append
                    (VSS.Strings.Conversions.To_Virtual_String
                       (Ada.Strings.Fixed."*" (Offset, " "))
                     & Line);
               end if;
            end loop;
         end;

         --  Add back snippet terminator
         Append (Res, "$0");
         return Res;
      end Post_Pretty_Print;

      use type LSP.Enumerations.InsertTextFormat;
   begin
      if LSP.Ada_Configurations.Completion_Formatting
        and then not Result.insertText.Is_Empty
        and then Result.insertTextFormat.Is_Set
        and then Result.insertTextFormat.Value = LSP.Enumerations.Snippet
      then
         declare
            Output      : Unbounded_String;
            PP_Messages : Pp.Scanner.Source_Message_Vector;
            S           : Virtual_String;
            Tmp_Unit    : Libadalang.Analysis.Analysis_Unit;
            Tmp_Context : constant Libadalang.Analysis.Analysis_Context :=
              Libadalang.Analysis.Create_Context;
         begin
            declare
               Full : constant String :=
                 VSS.Strings.Conversions.To_UTF_8_String
                   (Prefix & Encode_String (Result.insertText));
            begin
               Tmp_Unit :=
                 Libadalang.Analysis.Get_From_Buffer
                   (Context  => Tmp_Context,
                    Filename => "",
                    Buffer   => Full,
                    Rule     => Rule);
               Output := Gnatformat.Formatting.Format
                 (Unit           => Tmp_Unit,
                  Format_Options => Context.Get_Format_Options);
            exception
               when E : others =>
                  --  Failed to pretty print the snippet, keep the previous
                  --  value.
                  Context.Tracer.Trace_Exception (E);
                  return;
            end;

            S :=
              VSS.Strings.Conversions.To_Virtual_String (To_String (Output));

            if not S.Is_Empty then
               --  The text is already formatted, don't try to indent it
               Result.insertTextMode :=
                 (Is_Set => True,
                  Value  => LSP.Enumerations.asIs);

               --  Label is too verbose and can conflict with client filtering
               --  set filterText to the content of the span we are replacing.
               Result.filterText := Prefix;

               Result.textEdit :=
                 (Is_Set => True,
                  Value  =>
                    (Is_TextEdit => True,
                     TextEdit    =>
                       (a_range => Span,
                        newText => Post_Pretty_Print (Decode_String (S)))));
            end if;
         end;
      end if;
   end Pretty_Print_Snippet;

end LSP.Ada_Completions;
