------------------------------------------------------------------------------
--                         Language Server Protocol                         --
--                                                                          --
--                        Copyright (C) 2021, AdaCore                       --
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

--  Implementation of the command that allows to get project attribute values
--  from the currently loaded project tree.

with LSP.Ada_Commands;
with LSP.Errors;
with LSP.Server_Jobs;

package LSP.Ada_Handlers.Project_Attributes_Commands is

   type Command is new LSP.Ada_Commands.Command with private;

private

   type Command is new LSP.Ada_Commands.Command with record
      Pkg          : VSS.Strings.Virtual_String;
      Attribute    : VSS.Strings.Virtual_String;
      Index        : VSS.Strings.Virtual_String;
   end record;

   overriding function Create
     (Any : not null access LSP.Structures.LSPAny_Vector)
       return Command;

   overriding procedure Execute
     (Self     : Command;
      Handler  : not null access LSP.Ada_Handlers.Message_Handler'Class;
      Response : in out LSP.Structures.LSPAny_Or_Null;
      Error    : in out LSP.Errors.ResponseError_Optional);

   overriding function Priority (Self : Command)
     return LSP.Server_Jobs.Job_Priority
       is (LSP.Server_Jobs.Immediate);

   for Command'External_Tag use "als-get-project-attribute-value";

end LSP.Ada_Handlers.Project_Attributes_Commands;
