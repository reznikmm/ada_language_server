------------------------------------------------------------------------------
--                         Language Server Protocol                         --
--                                                                          --
--                        Copyright (C) 2018, AdaCore                       --
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

with LSP.Types;

package LSP.Clients.Response_Handlers is

   type Response_Handler is limited interface;

   not overriding procedure Initialize_Response
    (Self     : not null access Response_Handler;
     Request  : LSP.Types.LSP_Number;
     Response : LSP.Messages.Initialize_Response) is null;

   not overriding procedure Shutdown_Response
    (Self     : not null access Response_Handler;
     Request  : LSP.Types.LSP_Number;
     Response : LSP.Messages.ResponseMessage) is null;

   not overriding procedure Text_Document_Code_Action_Response
    (Self     : not null access Response_Handler;
     Request  : LSP.Types.LSP_Number;
     Response : LSP.Messages.CodeAction_Response) is null;

   not overriding procedure Text_Document_Completion_Response
    (Self     : not null access Response_Handler;
     Request  : LSP.Types.LSP_Number;
     Response : LSP.Messages.Completion_Response) is null;

   not overriding procedure Text_Document_Definition_Response
    (Self     : not null access Response_Handler;
     Request  : LSP.Types.LSP_Number;
     Response : LSP.Messages.Location_Response) is null;

   not overriding procedure Text_Document_Hover_Response
    (Self     : not null access Response_Handler;
     Request  : LSP.Types.LSP_Number;
     Response : LSP.Messages.Hover_Response) is null;

   not overriding procedure Text_Document_Highlight_Response
    (Self     : not null access Response_Handler;
     Request  : LSP.Types.LSP_Number;
     Response : LSP.Messages.Highlight_Response) is null;

   not overriding procedure Text_Document_References_Response
    (Self     : not null access Response_Handler;
     Request  : LSP.Types.LSP_Number;
     Response : LSP.Messages.Location_Response) is null;

   not overriding procedure Text_Document_Signature_Help_Response
    (Self     : not null access Response_Handler;
     Request  : LSP.Types.LSP_Number;
     Response : LSP.Messages.SignatureHelp_Response) is null;

   not overriding procedure Text_Document_Symbol_Response
    (Self     : not null access Response_Handler;
     Request  : LSP.Types.LSP_Number;
     Response : LSP.Messages.Symbol_Response) is null;

   not overriding procedure Workspace_Execute_Command_Response
    (Self     : not null access Response_Handler;
     Request  : LSP.Types.LSP_Number;
     Response : LSP.Messages.ExecuteCommand_Response) is null;

   not overriding procedure Workspace_Symbol_Response
    (Self     : not null access Response_Handler;
     Request  : LSP.Types.LSP_Number;
     Response : LSP.Messages.Symbol_Response) is null;

end LSP.Clients.Response_Handlers;
