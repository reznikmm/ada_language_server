------------------------------------------------------------------------------
--                         Language Server Protocol                         --
--                                                                          --
--                     Copyright (C) 2018-2019, AdaCore                     --
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
--
--  This package provides a context of Ada Language server.

with Ada.Strings.Unbounded;

with GNATCOLL.VFS;

with GNATdoc.Comments.Options;

with Gnatformat.Configuration;

with GPR2.Project.Tree;
with GPR2.Project.View;

with Langkit_Support.File_Readers; use Langkit_Support.File_Readers;
with Laltools.Common;

with Libadalang.Analysis;
with Libadalang.Common;
with Libadalang.Project_Provider;

with Utils.Command_Lines;
with Pp.Command_Lines;

with VSS.String_Vectors;
with VSS.Strings;

with LSP.Ada_Documents;
with LSP.Ada_File_Sets;
with LSP.Search;
with LSP.Structures;
with LSP.Tracers;

package LSP.Ada_Contexts is

   type Context (Tracer : not null LSP.Tracers.Tracer_Access) is
     tagged limited private;
   --  A context contains a non-aggregate project tree and its associated
   --  libadalang context.

   procedure Initialize
     (Self                : in out Context;
      File_Reader         : File_Reader_Interface'Class;
      Follow_Symlinks     : Boolean;
      Style               : GNATdoc.Comments.Options.Documentation_Style;
      As_Fallback_Context : Boolean := False);
   --  Initialize the context, set Follow_Symlinks flag.
   --  As_Fallback_Context should be set when we are creating the "fallback"
   --  context based on the empty project.
   --  Style is used to extract the documentation of entities, for tooltips
   --  in particular.

   procedure Load_Project
     (Self     : in out Context;
      Provider : Libadalang.Project_Provider.GPR2_Provider_And_Projects;
      Tree     : GPR2.Project.Tree.Object;
      Charset  : String);
   --  Use the given project tree, and root project within this project
   --  tree, as project for this context. Root must be a non-aggregate
   --  project tree representing the root of a hierarchy inside Tree.

   function Id (Self : Context) return VSS.Strings.Virtual_String;
   --  Return unique identifier of the context.

   procedure Reload (Self : in out Context);
   --  Reload the current context. This will invalidate and destroy any
   --  Libadalang related data, and recreate it from scratch.

   procedure Free (Self : in out Context);
   --  Release the memory associated to Self. You should not use the
   --  context after calling this.

   function URI_To_File
     (Self : Context; URI : LSP.Structures.DocumentUri)
      return GNATCOLL.VFS.Virtual_File;

   procedure Find_All_References
     (Self       : Context;
      Definition : Libadalang.Analysis.Defining_Name;
      Callback   :
        not null access procedure
          (Base_Id : Libadalang.Analysis.Base_Id;
           Kind    : Libadalang.Common.Ref_Result_Kind;
           Cancel  : in out Boolean));
   --  Finds all references to a given defining name in all units of the
   --  context.

   function Find_All_Overrides
     (Self              : Context;
      Decl              : Libadalang.Analysis.Basic_Decl;
      Imprecise_Results : out Boolean)
      return Libadalang.Analysis.Basic_Decl_Array;
   --  Finds all overriding subprograms of the given basic declaration.
   --  This is used to propose all the implementations of a given subprogram
   --  when textDocument/definition requests happen on dispatching calls.
   --  Imprecise_Results is set to True if we don't know whether the results
   --  are precise.
   --  Returns an empty array if Decl is null.

   function Find_All_Base_Declarations
     (Self              : Context;
      Decl              : Libadalang.Analysis.Basic_Decl;
      Imprecise_Results : out Boolean)
      return Libadalang.Analysis.Basic_Decl_Array;
   --  Given a subprogram declaration in Decl, find all the base subprograms
   --  that it inherits, not including self.
   --  Imprecise_Results is set to True if we don't know whether the results
   --  are precise.
   --  Returns an empty array if Decl is null.

   procedure Find_All_Calls
     (Self       : Context;
      Definition : Libadalang.Analysis.Defining_Name;
      Callback   :
        not null access procedure
          (Base_Id : Libadalang.Analysis.Base_Id;
           Kind    : Libadalang.Common.Ref_Result_Kind;
           Cancel  : in out Boolean));
   --  Return all the enclosing entities that call Definition in all sources
   --  known to this project.

   function Find_All_Env_Elements
     (Self     : Context;
      Name     : Libadalang.Analysis.Name;
      Seq      : Boolean := True;
      Seq_From : Libadalang.Analysis.Ada_Node'Class :=
        Libadalang.Analysis.No_Ada_Node)
      return Laltools.Common.Node_Vectors.Vector;
   --  Return all elements lexically named like Name, removing all duplicate
   --  and keeping the order given by LAL.
   --  If Seq is True and Seq_From is not empty, reduce the scope to the
   --  node above Seq_From.

   procedure Get_References_For_Renaming
     (Self              : Context;
      Definition        : Libadalang.Analysis.Defining_Name;
      Imprecise_Results : out Boolean;
      Callback          :
        not null access procedure
          (Base_Id : Libadalang.Analysis.Base_Id;
           Kind    : Libadalang.Common.Ref_Result_Kind;
           Cancel  : in out Boolean));
   --  Get all the references to a given defining name in all units for
   --  renaming purposes: for instance, when called on a tagged type primitive
   --  definition, references to the base subprograms it inherits and to the
   --  overriding ones are also returned.

   function Is_Fallback_Context (Self : Context) return Boolean;
   --  Return true if the given context is used as a fallback (i.e: used for files
   --  that do not belong to any known project subtree).

   function Is_Part_Of_Project
     (Self : Context; URI : LSP.Structures.DocumentUri) return Boolean;
   --  Check if the file designated by the given URI belongs to the project
   --  loaded in the Context.
   --  This returns False for fallback contexts, since fallback contexts
   --  are not linked to any project subtree.

   function Is_Part_Of_Project
     (Self : Context; File : GNATCOLL.VFS.Virtual_File) return Boolean;
   --  Check if given file belongs to the project loaded in the Context.
   --  This returns False for fallback contexts, since fallback contexts
   --  are not linked to any project subtree.

   function List_Files
     (Self : Context'CLass)
      return LSP
               .Ada_File_Sets
               .File_Sets
               .Set_Iterator_Interfaces
               .Reversible_Iterator'Class;
   --  Return the list of files known to this context.

   function File_Count (Self : Context) return Natural;
   --  Return number of files known to this context.

   function Get_PP_Options
     (Self : Context) return Utils.Command_Lines.Command_Line;
   --  Return the command line for the Pretty Printer

   function Get_Format_Options
     (Self : Context) return Gnatformat.Configuration.Format_Options_Type;
   --  Return the formatting options for Gnatformat

   function Get_Documentation_Style
     (Self : Context) return GNATdoc.Comments.Options.Documentation_Style;
   --  Get the documentation style used for this context.

   function Analysis_Units
     (Self : Context) return Libadalang.Analysis.Analysis_Unit_Array;
   --  Return the analysis units for all Ada sources known to this context

   function List_Source_Directories
      (Self : Context) return LSP.Ada_File_Sets.File_Sets.Set;
   --  List the source directories, including externally built projects' source
   --  directories when Include_Externally_Built is set to True.

   function List_Source_Extensions
     (Self : Context) return LSP.Ada_File_Sets.Extension_Sets.Set;
   --  List all extensions for the current project.

   function Get_AU
     (Self    : Context;
      File    : GNATCOLL.VFS.Virtual_File;
      Reparse : Boolean := False) return Libadalang.Analysis.Analysis_Unit;
   --  Wrapper around Libadalang.Analysis.Get_From_File, taking into
   --  account the context's charset, and only processing the file
   --  if it's an Ada source. Return No_Analysis_Unit if it's not.

   procedure Index_File
     (Self    : in out Context;
      File    : GNATCOLL.VFS.Virtual_File;
      Reparse : Boolean := True;
      PLE     : Boolean := True);
   --  Index the given file. This translates to refreshing the Libadalang
   --  Analysis_Unit associated to it.
   --  If PLE is True, Populate_Lexical_Env is called at the end, which will
   --  increase the speed of semantic requests.

   procedure Add_Invisible_Symbols
     (Self : in out Context;
      File : GNATCOLL.VFS.Virtual_File;
      Unit : Libadalang.Analysis.Analysis_Unit);
   --  Add invisible symbols present in Unit to the given context's cache,
   --  even if Unit is not known by this context.

   procedure Include_File
     (Self : in out Context; File : GNATCOLL.VFS.Virtual_File);
   --  Includes File in Self's source files

   procedure Exclude_File
     (Self : in out Context; File : GNATCOLL.VFS.Virtual_File);
   --  Excludes File from Self's source files

   procedure Index_Document
     (Self : in out Context; Document : in out LSP.Ada_Documents.Document);
   --  Index/reindex the given document in this context

   procedure Flush_Document
     (Self : in out Context; File : GNATCOLL.VFS.Virtual_File);
   --  Revert a document to the state of the file discarding any changes

   function LAL_Context
     (Self : Context) return Libadalang.Analysis.Analysis_Context;
   --  Return the LAL context corresponding to Self

   procedure Get_Any_Symbol
     (Self        : Context;
      Pattern     : LSP.Search.Search_Pattern'Class;
      Only_Public : Boolean;
      Callback    :
        not null access procedure
          (File : GNATCOLL.VFS.Virtual_File;
           Name : Libadalang.Analysis.Defining_Name;
           Stop : in out Boolean);
      Unit_Prefix : VSS.Strings.Virtual_String :=
        VSS.Strings.Empty_Virtual_String);
   --  Find symbols that match the given Pattern in all files of the context and
   --  call Callback for each.
   --  If Pattern is an empty string, all the symbols in all files will be
   --  returned.
   --  Name could contain a stale reference if the File
   --  was updated since last indexing operation. If Only_Public is True it
   --  will skip any "private" symbols (like symbols in private part or body).
   --  Unit_Prefix is used for additional filtering: when specified, only the
   --  symbols declared in this non-visible unit will be returned.

   function Charset (Self : Context) return String;
   --  Return the charset for this context

   function Project_Attribute_Values
     (View              : GPR2.Project.View.Object;
      Attribute         : GPR2.Q_Attribute_Id;
      Index             : String := "";
      Is_List_Attribute : out Boolean;
      Is_Known          : out Boolean)
      return VSS.String_Vectors.Virtual_String_Vector;
   --  Returns the values for the given project attribute.
   --  The corresponding attribute would have been set in the project as:
   --      for Attribute use "value";
   --      for Attribute use ("value_1", "value_2");
   --  or
   --      for Attribute (Index) use "value";
   --      for Attribute (Index) use ("value_1", "value_2");
   --
   --  If the attribute is not defined in the project itself, then the
   --  attribute is looked up in the project extended by the project (if
   --  any).
   --  A default value will always be returned if the attribute is known.
   --  Is_List_Attribute will be set to True if the queried attribute is a
   --  string list attribute (e.g: for Main use ("main1.adb", "main2.adb"))
   --  or set to False if it's a simple string one
   --  (e.g: for Target use "arm-eabi");
   --  Is_Known will be set to False if the attribute is not known (i.e: not
   --  registered in GPR2's knowledge database).

   function Project_Attribute_Value
     (View         : GPR2.Project.View.Object;
      Attribute    : GPR2.Q_Attribute_Id;
      Index        : String := "";
      Default      : String := "") return String;
   --  Returns the value for the given string project Attribute.
   --  Default is returned if the attribute wasn't set by the user and
   --  has no default value.
   --  The corresponding attribute would have been set in the project as:
   --      for Attribute use "value";
   --  or
   --      for Attribute (Index) use "value";
   --
   --  If the given attribute corresponds to a string list attribute instead
   --  (e.g: 'Main' attribute, which takes a list of mains) of a simple string
   --  attribute, the first value of the list is returned: if you want to get
   --  the full list use the Project_Attribute_Values function instead.

   function Project_Attribute_Value
     (Self         : Context;
      Attribute    : GPR2.Q_Attribute_Id;
      Index        : String := "";
      Default      : String := "") return String;
   --  Same as above, but computing the value directly from the context's
   --  root project view.

private

   type Context (Tracer : not null LSP.Tracers.Tracer_Access) is tagged limited
   record
      Id             : VSS.Strings.Virtual_String;
      Unit_Provider  : Libadalang.Analysis.Unit_Provider_Reference;
      Event_Handler  : Libadalang.Analysis.Event_Handler_Reference;
      LAL_Context    : Libadalang.Analysis.Analysis_Context;
      Charset        : Ada.Strings.Unbounded.Unbounded_String;

      Is_Fallback_Context : Boolean := False;
      --  Indicate that this is a "fallback" context, ie the context
      --  holding any file, in the case no valid project was loaded.

      Tree           : GPR2.Project.Tree.Object := GPR2.Project.Tree.Undefined;
      --  The loaded project tree: we need to keep a reference to this
      --  in order to figure out which files are Ada and which are not.

      Source_Files   : LSP.Ada_File_Sets.Indexed_File_Set;
      --  Cache for the list of Ada source files in the loaded project tree.

      Source_Dirs    : LSP.Ada_File_Sets.File_Sets.Set;
      --  All the source dirs in the loaded project, including
      --  the externally built projects

      Extension_Set : LSP.Ada_File_Sets.Extension_Sets.Set;
      --  All the ada extensions valid for the current project

      PP_Options : Utils.Command_Lines.Command_Line
                    (Pp.Command_Lines.Descriptor'Access);
      --  Object to keep gnatpp options

      Format_Options : Gnatformat.Configuration.Format_Options_Type;

      Style : GNATdoc.Comments.Options.Documentation_Style :=
        GNATdoc.Comments.Options.GNAT;
      --  The context's documentation style.

      Follow_Symlinks : Boolean := True;
      --  See LSP.Ada_Handlers for description

      Reader_Reference : Langkit_Support.File_Readers.File_Reader_Reference;
      --  A reference to the file reader created for this context
   end record;

   function LAL_Context
     (Self : Context) return Libadalang.Analysis.Analysis_Context is
     (Self.LAL_Context);

   function List_Files (Self : Context'Class)
     return LSP.Ada_File_Sets.File_Sets.Set_Iterator_Interfaces
       .Reversible_Iterator'Class is (Self.Source_Files.Iterate);

   function List_Source_Directories
     (Self : Context) return LSP.Ada_File_Sets.File_Sets.Set
   is (Self.Source_Dirs);

   function File_Count (Self : Context) return Natural
   is (Self.Source_Files.Length);

   function Get_PP_Options (Self : Context) return
     Utils.Command_Lines.Command_Line is (Self.PP_Options);

   function Get_Format_Options
     (Self : Context)
      return Gnatformat.Configuration.Format_Options_Type
   is (Self.Format_Options);

   function Get_Documentation_Style (Self : Context) return
     GNATdoc.Comments.Options.Documentation_Style is (Self.Style);

end LSP.Ada_Contexts;
