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

with VSS.JSON.Pull_Readers.Simple;
with VSS.JSON.Streams;
with VSS.Stream_Element_Vectors.Conversions;
with VSS.Strings.Conversions;
with VSS.Text_Streams.Memory_UTF8_Input;
with VSS.Text_Streams.Memory_UTF8_Output;

with LSP.Client_Notification_Receivers;
with LSP.Clients.Request_Handlers;
with LSP.Clients.Response_Handlers;
with LSP.JSON_Streams;
with LSP.Messages.Server_Requests; use LSP.Messages.Server_Requests;
with LSP.Messages.Server_Notifications; use LSP.Messages.Server_Notifications;
with LSP.Messages.Client_Notifications;
use LSP.Messages.Client_Notifications;
with LSP.Messages.Server_Responses;
with LSP.Messages.Client_Responses;
with LSP.Messages.Client_Requests;

package body LSP.Clients is

   package Decoders is

      --  Responses

      procedure Initialize_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class);

      procedure Shutdown_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class);

      procedure Text_Document_Code_Action_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class);

      procedure Text_Document_Completion_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class);

      procedure Text_Document_Definition_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class);

      procedure Text_Document_Type_Definition_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class);

      procedure Text_Document_Hover_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class);

      procedure Text_Document_Folding_Range_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class);

      procedure Text_Document_Highlight_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class);

      procedure Text_Document_References_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class);

      procedure Text_Document_Signature_Help_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class);

      procedure Text_Document_Symbol_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class);

      procedure Workspace_Execute_Command_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class);

      procedure Workspace_Symbol_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class);

      --  Notifications

      procedure Show_Message
        (Stream  : access Ada.Streams.Root_Stream_Type'Class;
         Handler : access LSP.Client_Notification_Receivers
         .Client_Notification_Receiver'Class;
         Client  : LSP.Raw_Clients.Raw_Client'Class;
         Token   : LSP.Types.LSP_Number_Or_String);

      procedure Log_Message
        (Stream  : access Ada.Streams.Root_Stream_Type'Class;
         Handler : access LSP.Client_Notification_Receivers
         .Client_Notification_Receiver'Class;
         Client  : LSP.Raw_Clients.Raw_Client'Class;
         Token   : LSP.Types.LSP_Number_Or_String);

      procedure Publish_Diagnostics
        (Stream  : access Ada.Streams.Root_Stream_Type'Class;
         Handler : access LSP.Client_Notification_Receivers
         .Client_Notification_Receiver'Class;
         Client  : LSP.Raw_Clients.Raw_Client'Class;
         Token   : LSP.Types.LSP_Number_Or_String);

      procedure Progress
        (Stream  : access Ada.Streams.Root_Stream_Type'Class;
         Handler : access LSP.Client_Notification_Receivers
         .Client_Notification_Receiver'Class;
         Client  : LSP.Raw_Clients.Raw_Client'Class;
         Token   : LSP.Types.LSP_Number_Or_String);

   end Decoders;

   -------------------------
   -- Allocate_Request_Id --
   -------------------------

   function Allocate_Request_Id
     (Self : in out Client'Class) return LSP.Types.LSP_Number_Or_String
   is
      Id : VSS.Strings.Virtual_String := Self.Request_Id_Prefix;

   begin
      Self.Request_Id := Self.Request_Id + 1;

      if not Id.Is_Empty then
         return (True, Self.Request_Id);

      else
         declare
            Image : constant Wide_Wide_String :=
              LSP.Types.LSP_Number'Wide_Wide_Image (Self.Request_Id);

         begin
            Id.Append ('-');
            Id.Append
              (VSS.Strings.To_Virtual_String
                 (Image (Image'First + 1 .. Image'Last)));

            return (False, Id);
         end;
      end if;
   end Allocate_Request_Id;

   --------------
   -- Decoders --
   --------------

   package body Decoders is

      -------------------------
      -- Initialize_Response --
      -------------------------

      procedure Initialize_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class)
      is
         Response : LSP.Messages.Server_Responses.Initialize_Response
           (Is_Error);
      begin
         LSP.Messages.Server_Responses.Initialize_Response'Read
           (Stream, Response);
         Handler.Initialize_Response (Request, Response);
      end Initialize_Response;

      -----------------------
      -- Shutdown_Response --
      -----------------------

      procedure Shutdown_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class)
      is
         Response : LSP.Messages.Server_Responses.Shutdown_Response (Is_Error);
      begin
         LSP.Messages.Server_Responses.Shutdown_Response'Read
           (Stream, Response);
         Handler.Shutdown_Response (Request, Response);
      end Shutdown_Response;

      ----------------------------------------
      -- Text_Document_Code_Action_Response --
      ----------------------------------------

      procedure Text_Document_Code_Action_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class)
      is
         Response : LSP.Messages.Server_Responses.CodeAction_Response
           (Is_Error);
      begin
         LSP.Messages.Server_Responses.CodeAction_Response'Read
           (Stream, Response);
         Handler.Text_Document_Code_Action_Response (Request, Response);
      end Text_Document_Code_Action_Response;

      ---------------------------------------
      -- Text_Document_Completion_Response --
      ---------------------------------------

      procedure Text_Document_Completion_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class)
      is
         Response : LSP.Messages.Server_Responses.Completion_Response
           (Is_Error);
      begin
         LSP.Messages.Server_Responses.Completion_Response'Read
           (Stream, Response);
         Handler.Text_Document_Completion_Response (Request, Response);
      end Text_Document_Completion_Response;

      ---------------------------------------
      -- Text_Document_Definition_Response --
      ---------------------------------------

      procedure Text_Document_Definition_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class)
      is
         Response : LSP.Messages.Server_Responses.Location_Response (Is_Error);
      begin
         LSP.Messages.Server_Responses.Location_Response'Read
           (Stream, Response);
         Handler.Text_Document_Definition_Response (Request, Response);
      end Text_Document_Definition_Response;

      --------------------------------------------
      -- Text_Document_Type_Definition_Response --
      --------------------------------------------

      procedure Text_Document_Type_Definition_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class)
      is
         Response : LSP.Messages.Server_Responses.Location_Response (Is_Error);
      begin
         LSP.Messages.Server_Responses.Location_Response'Read
           (Stream, Response);
         Handler.Text_Document_Type_Definition_Response (Request, Response);
      end Text_Document_Type_Definition_Response;

      ----------------------------------
      -- Text_Document_Hover_Response --
      ----------------------------------

      procedure Text_Document_Hover_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class)
      is
         Response : LSP.Messages.Server_Responses.Hover_Response (Is_Error);
      begin
         LSP.Messages.Server_Responses.Hover_Response'Read (Stream, Response);
         Handler.Text_Document_Hover_Response (Request, Response);
      end Text_Document_Hover_Response;

      ------------------------------------------
      -- Text_Document_Folding_Range_Response --
      ------------------------------------------

      procedure Text_Document_Folding_Range_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class)
      is
         Response : LSP.Messages.Server_Responses.FoldingRange_Response
           (Is_Error);
      begin
         LSP.Messages.Server_Responses.FoldingRange_Response'Read
           (Stream, Response);
         Handler.Text_Document_Folding_Range_Response (Request, Response);
      end Text_Document_Folding_Range_Response;

      --------------------------------------
      -- Text_Document_Highlight_Response --
      --------------------------------------

      procedure Text_Document_Highlight_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class)
      is
         Response : LSP.Messages.Server_Responses.Highlight_Response
           (Is_Error);
      begin
         LSP.Messages.Server_Responses.Highlight_Response'Read
           (Stream, Response);
         Handler.Text_Document_Highlight_Response (Request, Response);
      end Text_Document_Highlight_Response;

      ---------------------------------------
      -- Text_Document_References_Response --
      ---------------------------------------

      procedure Text_Document_References_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class)
      is
         Response : LSP.Messages.Server_Responses.Location_Response (Is_Error);
      begin
         LSP.Messages.Server_Responses.Location_Response'Read
           (Stream, Response);
         Handler.Text_Document_References_Response (Request, Response);
      end Text_Document_References_Response;

      -------------------------------------------
      -- Text_Document_Signature_Help_Response --
      -------------------------------------------

      procedure Text_Document_Signature_Help_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class)
      is
         Response : LSP.Messages.Server_Responses
           .SignatureHelp_Response (Is_Error);
      begin
         LSP.Messages.Server_Responses.SignatureHelp_Response'Read
           (Stream, Response);
         Handler.Text_Document_Signature_Help_Response (Request, Response);
      end Text_Document_Signature_Help_Response;

      -----------------------------------
      -- Text_Document_Symbol_Response --
      -----------------------------------

      procedure Text_Document_Symbol_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class)
      is
         Response : LSP.Messages.Server_Responses.Symbol_Response (Is_Error);
      begin
         LSP.Messages.Server_Responses.Symbol_Response'Read (Stream, Response);
         Handler.Text_Document_Symbol_Response (Request, Response);
      end Text_Document_Symbol_Response;

      ----------------------------------------
      -- Workspace_Execute_Command_Response --
      ----------------------------------------

      procedure Workspace_Execute_Command_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class)
      is
         Response : LSP.Messages.Server_Responses .ExecuteCommand_Response
           (Is_Error);
      begin
         LSP.Messages.Server_Responses.ExecuteCommand_Response'Read
           (Stream, Response);
         Handler.Workspace_Execute_Command_Response (Request, Response);
      end Workspace_Execute_Command_Response;

      -------------------------------
      -- Workspace_Symbol_Response --
      -------------------------------

      procedure Workspace_Symbol_Response
        (Stream   : access Ada.Streams.Root_Stream_Type'Class;
         Request  : LSP.Types.LSP_Number_Or_String;
         Is_Error : Boolean;
         Handler  : access
           LSP.Clients.Response_Handlers.Response_Handler'Class)
      is
         Response : LSP.Messages.Server_Responses.Symbol_Response (Is_Error);
      begin
         LSP.Messages.Server_Responses.Symbol_Response'Read (Stream, Response);
         Handler.Workspace_Symbol_Response (Request, Response);
      end Workspace_Symbol_Response;

      -----------------
      -- Log_Message --
      -----------------

      procedure Log_Message
        (Stream  : access Ada.Streams.Root_Stream_Type'Class;
         Handler : access LSP.Client_Notification_Receivers
         .Client_Notification_Receiver'Class;
         Client  : LSP.Raw_Clients.Raw_Client'Class;
         Token   : LSP.Types.LSP_Number_Or_String)
      is
         pragma Unreferenced (Token);
         Message : LogMessage_Notification;
      begin
         LogMessage_Notification'Read (Stream, Message);
         Handler.On_Log_Message (Message.params, Client.Server_Language);
      end Log_Message;

      -------------------------
      -- Publish_Diagnostics --
      -------------------------

      procedure Publish_Diagnostics
        (Stream  : access Ada.Streams.Root_Stream_Type'Class;
         Handler : access LSP.Client_Notification_Receivers
         .Client_Notification_Receiver'Class;
         Client  : LSP.Raw_Clients.Raw_Client'Class;
         Token   : LSP.Types.LSP_Number_Or_String)
      is
         pragma Unreferenced (Token);
         Message : PublishDiagnostics_Notification;
      begin
         PublishDiagnostics_Notification'Read (Stream, Message);
         Handler.On_Publish_Diagnostics
           (Message.params, Client.Server_Language);
      end Publish_Diagnostics;

      ------------------
      -- Show_Message --
      ------------------

      procedure Show_Message
        (Stream  : access Ada.Streams.Root_Stream_Type'Class;
         Handler : access LSP.Client_Notification_Receivers
         .Client_Notification_Receiver'Class;
         Client  : LSP.Raw_Clients.Raw_Client'Class;
         Token   : LSP.Types.LSP_Number_Or_String)
      is
         pragma Unreferenced (Token);
         Message : ShowMessage_Notification;
      begin
         ShowMessage_Notification'Read (Stream, Message);
         Handler.On_Show_Message (Message.params, Client.Server_Language);
      end Show_Message;

      --------------
      -- Progress --
      --------------

      procedure Progress
        (Stream  : access Ada.Streams.Root_Stream_Type'Class;
         Handler : access LSP.Client_Notification_Receivers
         .Client_Notification_Receiver'Class;
         Client  : LSP.Raw_Clients.Raw_Client'Class;
         Token   : LSP.Types.LSP_Number_Or_String) is
         pragma Unreferenced (Client);
      begin
         case Handler.Get_Progress_Type (Token) is
            when LSP.Client_Notification_Receivers.ProgressParams =>
               declare
                  Message : Progress_Notification;
               begin
                  Progress_Notification'Read (Stream, Message);
                  Handler.On_Progress (Message.params);
               end;

            when LSP.Client_Notification_Receivers.SymbolInformation =>
               declare
                  Message : SymbolInformation_Vectors_Notification;
               begin
                  SymbolInformation_Vectors_Notification'Read
                    (Stream, Message);
                  Handler.On_Progress_SymbolInformation_Vector
                    (Message.params);
               end;
         end case;
      end Progress;

   end Decoders;

   -------------------
   -- Error_Message --
   -------------------

   overriding function Error_Message
     (Self : Client) return VSS.Strings.Virtual_String is
   begin
      return Self.Error_Message;
   end Error_Message;

   --------------------------
   -- On_Exit_Notification --
   --------------------------

   overriding procedure On_Exit_Notification (Self : access Client) is
      Message : LSP.Messages.Server_Notifications.Exit_Notification;
   begin
      Self.Send_Notification ("exit", Message);
   end On_Exit_Notification;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (Self : in out Client'Class) is
      function "-"
        (Text : String) return Ada.Strings.Unbounded.Unbounded_String
          renames Ada.Strings.Unbounded.To_Unbounded_String;
   begin
      Self.Notif_Decoders.Insert
        (-"window/showMessage",
         Decoders.Show_Message'Access);
      Self.Notif_Decoders.Insert
        (-"window/logMessage",
         Decoders.Log_Message'Access);
      --  "telemetry/event",
      Self.Notif_Decoders.Insert
        (-"textDocument/publishDiagnostics",
         Decoders.Publish_Diagnostics'Access);
      Self.Notif_Decoders.Insert
        (-"$/progress",
         Decoders.Progress'Access);
   end Initialize;

   ------------------------
   -- Initialize_Request --
   ------------------------

   procedure Initialize_Request
     (Self    : in out Client'Class;
      Request : out LSP.Types.LSP_Number_Or_String;
      Value   : LSP.Messages.InitializeParams)
   is
      Message : LSP.Messages.Server_Requests.Initialize_Request :=
        (params => Value, others => <>);
   begin
      Self.Send_Request
        (Request, "initialize", Decoders.Initialize_Response'Access, Message);
   end Initialize_Request;

   --------------------
   -- On_Raw_Message --
   --------------------

   overriding procedure On_Raw_Message
     (Self    : in out Client;
      Data    : Ada.Strings.Unbounded.Unbounded_String;
      Success : in out Boolean)
   is
      use type VSS.Strings.Virtual_String;

      procedure Look_Ahead
        (Id       : out LSP.Types.LSP_Number_Or_String;
         Method   : out LSP.Types.Optional_Virtual_String;
         Token    : out LSP.Types.LSP_Number_Or_String;
         Is_Error : in out Boolean);

      Memory : aliased
        VSS.Text_Streams.Memory_UTF8_Input.Memory_UTF8_Input_Stream;

      ----------------
      -- Look_Ahead --
      ----------------

      procedure Look_Ahead
        (Id       : out LSP.Types.LSP_Number_Or_String;
         Method   : out LSP.Types.Optional_Virtual_String;
         Token    : out LSP.Types.LSP_Number_Or_String;
         Is_Error : in out Boolean)
      is
         use all type VSS.JSON.Streams.JSON_Stream_Element_Kind;

         R  : aliased VSS.JSON.Pull_Readers.Simple.JSON_Simple_Pull_Reader;
         JS : aliased LSP.JSON_Streams.JSON_Stream (False, R'Unchecked_Access);

      begin
         R.Set_Stream (Memory'Unchecked_Access);
         R.Read_Next;
         pragma Assert (R.Is_Start_Document);
         R.Read_Next;
         pragma Assert (R.Is_Start_Object);
         R.Read_Next;
         while not R.Is_End_Object loop
            pragma Assert (R.Is_Key_Name);
            declare
               Key : constant String :=
                 VSS.Strings.Conversions.To_UTF_8_String (R.Key_Name);
            begin
               R.Read_Next;

               if Key = "id" then
                  case R.Element_Kind is
                     when String_Value =>
                        Id :=
                          (Is_Number => False,
                           String    => R.String_Value);

                     when Number_Value =>
                        Id :=
                          (Is_Number => True,
                           Number    => LSP.Types.LSP_Number
                             (R.Number_Value.Integer_Value));

                     when others =>
                        raise Constraint_Error;
                  end case;
                  R.Read_Next;

               elsif Key = "method" then
                  pragma Assert (R.Is_String_Value);
                  Method := (True, R.String_Value);
                  R.Read_Next;

               elsif Key = "error" then
                  Is_Error := True;
                  JS.Skip_Value;

               elsif Key = "params" then
                  --  parse 'params' object to get 'token' value
                  --  from a notification if any

                  pragma Assert (R.Is_Start_Object);
                  R.Read_Next;

                  while not R.Is_End_Object loop
                     pragma Assert (R.Is_Key_Name);
                     declare
                        Key : constant String :=
                          VSS.Strings.Conversions.To_UTF_8_String (R.Key_Name);
                     begin
                        R.Read_Next;

                        if Key = "token" then
                           case R.Element_Kind is
                              when String_Value =>
                                 Token :=
                                   (Is_Number => False,
                                    String    => R.String_Value);

                              when Number_Value =>
                                 Token :=
                                   (Is_Number => True,
                                    Number    => LSP.Types.LSP_Number
                                      (R.Number_Value.Integer_Value));

                              when others =>
                                 raise Constraint_Error;
                           end case;
                           R.Read_Next;

                        else
                           JS.Skip_Value;
                        end if;
                     end;
                  end loop;
                  R.Read_Next;

               else
                  JS.Skip_Value;
               end if;
            end;
         end loop;

         Memory.Rewind;
      end Look_Ahead;

      Reader : aliased VSS.JSON.Pull_Readers.Simple.JSON_Simple_Pull_Reader;
      Stream : aliased LSP.JSON_Streams.JSON_Stream
        (Is_Server_Side => False, R => Reader'Unchecked_Access);
      Id     : LSP.Types.LSP_Number_Or_String;
      Method : LSP.Types.Optional_Virtual_String;
      Token  : LSP.Types.LSP_Number_Or_String :=
        (Is_Number => False, String => VSS.Strings.Empty_Virtual_String);

      Is_Error : Boolean := False;

   begin
      Self.Error_Message.Clear;
      --  First, cleanup error message from previous value.

      Memory.Set_Data
        (VSS.Stream_Element_Vectors.Conversions.Unchecked_From_Unbounded_String
           (Data));

      Look_Ahead (Id, Method, Token, Is_Error);
      Reader.Set_Stream (Memory'Unchecked_Access);
      Stream.R.Read_Next;
      pragma Assert (Stream.R.Is_Start_Document);
      Stream.R.Read_Next;
      pragma Assert (Stream.R.Is_Start_Object);

      if LSP.Types.Assigned (Id) then
         if Method.Is_Set then
            --   Request from server;
            if Method.Value = "workspace/applyEdit" then
               declare
                  Request : LSP.Messages.Client_Requests
                              .Workspace_Apply_Edit_Request;
               begin
                  LSP.Messages.Client_Requests.Workspace_Apply_Edit_Request'
                    Read (Stream'Access, Request);

                  Self.Request_Handler.Workspace_Apply_Edit
                    (Request => Id,
                     Params  => Request.params);
               end;
            elsif Method.Value = "workspace/workspaceFolders" then
               declare
                  Request : LSP.Messages.RequestMessage;
               begin
                  LSP.Messages.RequestMessage'Read (Stream'Access, Request);
                  Self.Request_Handler.Workspace_Folders (Request => Id);
               end;
            elsif Method.Value = "workspace/configuration" then
               declare
                  Request : LSP.Messages.Client_Requests
                              .Workspace_Configuration_Request;
               begin
                  LSP.Messages.Client_Requests.Workspace_Configuration_Request'
                    Read (Stream'Access, Request);

                  Self.Request_Handler.Workspace_Configuration
                    (Request => Id,
                     Params  => Request.params);
               end;
            elsif Method.Value = "window/showMessage" then
               declare
                  Request : LSP.Messages.Client_Requests.ShowMessage_Request;
               begin
                  LSP.Messages.Client_Requests.ShowMessage_Request'
                    Read (Stream'Access, Request);

                  Self.Request_Handler.Window_Show_Message
                    (Request => Id,
                     Params  => Request.params);
               end;
            elsif Method.Value = "window/workDoneProgress/create" then
               declare
                  Request : LSP.Messages.Client_Requests
                              .WorkDoneProgressCreate_Request;
               begin
                  LSP.Messages.Client_Requests.WorkDoneProgressCreate_Request'
                    Read (Stream'Access, Request);

                  Self.Request_Handler.Window_Work_Done_Progress_Create
                    (Request => Id,
                     Params  => Request.params);
               end;
            elsif Method.Value = "client/registerCapability" then
               declare
                  Request : LSP.Messages.Client_Requests
                              .RegisterCapability_Request;
               begin
                  LSP.Messages.Client_Requests.RegisterCapability_Request'
                    Read (Stream'Access, Request);

                  Self.Request_Handler.Client_Register_Capability
                    (Request => Id,
                     Params  => Request.params);
               end;
            elsif Method.Value = "client/unregisterCapability" then
               declare
                  Request : LSP.Messages.Client_Requests
                              .UnregisterCapability_Request;
               begin
                  LSP.Messages.Client_Requests.UnregisterCapability_Request'
                    Read (Stream'Access, Request);

                  Self.Request_Handler.Client_Unregister_Capability
                    (Request => Id,
                     Params  => Request.params);
               end;
            else
               declare
                  Error : LSP.Messages.ResponseMessage :=
                    (Is_Error => True,
                     error =>
                       (True,
                        (code    => LSP.Messages.MethodNotFound,
                         message => "Unknown method:" & Method.Value,
                         data    => <>)),
                     others => <>);
               begin
                  Self.Send_Response (Id, Error);
               end;
            end if;
         else
            --  Response from server

            if Self.Request_Map.Contains (Id) then
               Self.Request_Map (Id).all
                 (Stream'Access, Id, Is_Error, Self.Response_Handler);
            else
               Self.Error_Message :=
                 VSS.Strings.To_Virtual_String
                   ("Unknown request id '"
                    & VSS.Strings.Conversions.To_Wide_Wide_String
                      (LSP.Types.To_Virtual_String (Id))
                    & ''');
               Success := False;
            end if;
         end if;

      elsif Method.Is_Set then
         --  Notification from server

         declare
            Position : constant Notification_Maps.Cursor :=
              Self.Notif_Decoders.Find
                (VSS.Strings.Conversions.To_Unbounded_UTF_8_String
                   (Method.Value));

         begin
            if Notification_Maps.Has_Element (Position) then
               Notification_Maps.Element (Position).all
                 (Stream'Access, Self.Notification, Self, Token);
            end if;
         end;
      end if;
   end On_Raw_Message;

   -----------------------
   -- Request_Id_Prefix --
   -----------------------

   function Request_Id_Prefix
     (Self : Client) return VSS.Strings.Virtual_String is
   begin
      return VSS.Strings.Empty_Virtual_String;
   end Request_Id_Prefix;

   -----------------------
   -- Send_Notification --
   -----------------------

   procedure Send_Notification
     (Self   : in out Client'Class;
      Method : VSS.Strings.Virtual_String;
      Value  : in out LSP.Messages.NotificationMessage'Class)
   is
      JS     : aliased LSP.JSON_Streams.JSON_Stream
        (Is_Server_Side => False, R => null);
      Output : aliased
        VSS.Text_Streams.Memory_UTF8_Output.Memory_UTF8_Output_Stream;

   begin
      JS.Set_Stream (Output'Unchecked_Access);
      Value.jsonrpc := "2.0";
      Value.method := Method;
      LSP.Messages.NotificationMessage'Class'Write (JS'Access, Value);
      JS.End_Document;
      Self.Send_Buffer (Output.Buffer);
   end Send_Notification;

   ------------------
   -- Send_Request --
   ------------------

   procedure Send_Request
     (Self    : in out Client'Class;
      Request : out LSP.Types.LSP_Number_Or_String;
      Method  : VSS.Strings.Virtual_String;
      Decoder : Response_Decoder;
      Value   : in out LSP.Messages.RequestMessage'Class)
   is
      JS     : aliased LSP.JSON_Streams.JSON_Stream
        (Is_Server_Side => False, R => null);
      Output : aliased
        VSS.Text_Streams.Memory_UTF8_Output.Memory_UTF8_Output_Stream;

   begin
      JS.Set_Stream (Output'Unchecked_Access);
      Request := Self.Allocate_Request_Id;
      Self.Request_Map.Insert (Request, Decoder);

      Value.jsonrpc := "2.0";
      Value.method := Method;
      Value.id := Request;
      LSP.Messages.RequestMessage'Class'Write (JS'Access, Value);
      JS.End_Document;
      Self.Send_Buffer (Output.Buffer);
   end Send_Request;

   ------------------------------
   -- Set_Notification_Handler --
   ------------------------------

   procedure Set_Notification_Handler
     (Self  : in out Client'Class;
      Value : access Client_Notification_Receivers
      .Client_Notification_Receiver'Class) is
   begin
      Self.Notification := Value;
   end Set_Notification_Handler;

   -------------------------
   -- Set_Request_Handler --
   -------------------------

   procedure Set_Request_Handler
     (Self  : in out Client'Class;
      Value : access LSP.Clients.Request_Handlers.Request_Handler'Class) is
   begin
      Self.Request_Handler := Value;
   end Set_Request_Handler;

   --------------------------
   -- Set_Response_Handler --
   --------------------------

   procedure Set_Response_Handler
     (Self  : in out Client'Class;
      Value : access LSP.Clients.Response_Handlers.Response_Handler'Class) is
   begin
      Self.Response_Handler := Value;
   end Set_Response_Handler;

   ----------------------
   -- Shutdown_Request --
   ----------------------

   procedure Shutdown_Request
     (Self    : in out Client'Class;
      Request : out LSP.Types.LSP_Number_Or_String)
   is
      Message : LSP.Messages.Server_Requests.Shutdown_Request;
   begin
      Self.Send_Request
        (Request,
         "shutdown",
         Decoders.Shutdown_Response'Access,
         Message);
   end Shutdown_Request;

   -------------------
   -- Send_Response --
   -------------------

   procedure Send_Response
     (Self    : in out Client'Class;
      Request : LSP.Types.LSP_Number_Or_String;
      Value   : in out LSP.Messages.ResponseMessage'Class)
   is
      JS     : aliased LSP.JSON_Streams.JSON_Stream
        (Is_Server_Side => False, R => null);
      Output : aliased
        VSS.Text_Streams.Memory_UTF8_Output.Memory_UTF8_Output_Stream;

   begin
      JS.Set_Stream (Output'Unchecked_Access);
      Value.jsonrpc := "2.0";
      Value.id := Request;
      LSP.Messages.ResponseMessage'Class'Write (JS'Access, Value);
      JS.End_Document;
      Self.Send_Buffer (Output.Buffer);
   end Send_Response;

   ---------------------------------------
   -- Text_Document_Code_Action_Request --
   ---------------------------------------

   procedure Text_Document_Code_Action_Request
     (Self    : in out Client'Class;
      Request : out LSP.Types.LSP_Number_Or_String;
      Value   : LSP.Messages.CodeActionParams)
   is
      Message : CodeAction_Request := (params => Value, others => <>);
   begin
      Self.Send_Request
        (Request,
         "textDocument/codeAction",
         Decoders.Text_Document_Code_Action_Response'Access,
         Message);
   end Text_Document_Code_Action_Request;

   --------------------------------------
   -- Text_Document_Completion_Request --
   --------------------------------------

   procedure Text_Document_Completion_Request
     (Self    : in out Client'Class;
      Request : out LSP.Types.LSP_Number_Or_String;
      Value   : LSP.Messages.TextDocumentPositionParams)
   is
      Message : Completion_Request := (params => Value, others => <>);
   begin
      Self.Send_Request
        (Request,
         "textDocument/completion",
         Decoders.Text_Document_Completion_Response'Access,
         Message);
   end Text_Document_Completion_Request;

   --------------------------------------
   -- Text_Document_Definition_Request --
   --------------------------------------

   procedure Text_Document_Definition_Request
     (Self    : in out Client'Class;
      Request : out LSP.Types.LSP_Number_Or_String;
      Value   : LSP.Messages.DefinitionParams)
   is
      Message : Definition_Request := (params => Value, others => <>);
   begin
      Self.Send_Request
        (Request,
         "textDocument/definition",
         Decoders.Text_Document_Definition_Response'Access,
         Message);
   end Text_Document_Definition_Request;

   -------------------------------------------
   -- Text_Document_Type_Definition_Request --
   -------------------------------------------

   procedure Text_Document_Type_Definition_Request
     (Self     : in out Client'Class;
      Request  : out LSP.Types.LSP_Number_Or_String;
      Value    : LSP.Messages.TextDocumentPositionParams)
   is
      Message : Type_Definition_Request := (params => Value, others => <>);
   begin
      Self.Send_Request
        (Request,
         "textDocument/typeDefinition",
         Decoders.Text_Document_Type_Definition_Response'Access,
         Message);
   end Text_Document_Type_Definition_Request;

   -------------------------------------------
   -- On_DidChangeTextDocument_Notification --
   -------------------------------------------

   overriding procedure On_DidChangeTextDocument_Notification
     (Self  : access Client;
      Value : LSP.Messages.DidChangeTextDocumentParams)
   is
      Message : DidChangeTextDocument_Notification :=
        (params => Value, others => <>);
   begin
      Self.Send_Notification ("textDocument/didChange", Message);
   end On_DidChangeTextDocument_Notification;

   ------------------------------------------
   -- On_DidCloseTextDocument_Notification --
   ------------------------------------------

   overriding procedure On_DidCloseTextDocument_Notification
     (Self  : access Client;
      Value : LSP.Messages.DidCloseTextDocumentParams)
   is
      Message : DidCloseTextDocument_Notification :=
        (params => Value, others => <>);
   begin
      Self.Send_Notification ("textDocument/didClose", Message);
   end On_DidCloseTextDocument_Notification;

   -----------------------------------------
   -- On_DidOpenTextDocument_Notification --
   -----------------------------------------

   overriding procedure On_DidOpenTextDocument_Notification
     (Self  : access Client;
      Value : LSP.Messages.DidOpenTextDocumentParams)
   is
      Message : DidOpenTextDocument_Notification :=
        (params => Value, others => <>);
   begin
      Self.Send_Notification ("textDocument/didOpen", Message);
   end On_DidOpenTextDocument_Notification;

   -----------------------------------------
   -- On_DidSaveTextDocument_Notification --
   -----------------------------------------

   overriding procedure On_DidSaveTextDocument_Notification
     (Self  : access Client;
      Value : LSP.Messages.DidSaveTextDocumentParams)
   is
      Message : DidSaveTextDocument_Notification :=
        (params => Value, others => <>);
   begin
      Self.Send_Notification ("textDocument/didSave", Message);
   end On_DidSaveTextDocument_Notification;

   ----------------------------
   -- On_Cancel_Notification --
   ----------------------------

   overriding procedure On_Cancel_Notification
     (Self  : access Client;
      Value : LSP.Messages.CancelParams)
   is
      Message : Cancel_Notification :=
        (params => Value, others => <>);
   begin
      Self.Send_Notification ("$/cancelRequest", Message);
   end On_Cancel_Notification;

   ------------------------------
   -- On_SetTrace_Notification --
   ------------------------------

   overriding procedure On_SetTrace_Notification
     (Self  : access Client;
      Value : LSP.Messages.SetTraceParams)
   is
      Message : SetTrace_Notification :=
        (params => Value, others => <>);
   begin
      Self.Send_Notification ("$/setTrace", Message);
   end On_SetTrace_Notification;

   ------------------------------------
   -- On_DidCreateFiles_Notification --
   ------------------------------------

   overriding procedure On_DidCreateFiles_Notification
     (Self  : access Client;
      Value : LSP.Messages.CreateFilesParams)
   is
      Message : DidCreateFiles_Notification :=
        (params => Value, others => <>);
   begin
      Self.Send_Notification ("workspace/didCreateFiles", Message);
   end On_DidCreateFiles_Notification;

   ------------------------------------
   -- On_DidRenameFiles_Notification --
   ------------------------------------

   overriding procedure On_DidRenameFiles_Notification
     (Self  : access Client;
      Value : LSP.Messages.RenameFilesParams)
   is
      Message : DidRenameFiles_Notification :=
        (params => Value, others => <>);
   begin
      Self.Send_Notification ("workspace/didRenameFiles", Message);
   end On_DidRenameFiles_Notification;

   ------------------------------------
   -- On_DidDeleteFiles_Notification --
   ------------------------------------

   overriding procedure On_DidDeleteFiles_Notification
     (Self  : access Client;
      Value : LSP.Messages.DeleteFilesParams)
   is
      Message : DidDeleteFiles_Notification :=
        (params => Value, others => <>);
   begin
      Self.Send_Notification ("workspace/didDeleteFiles", Message);
   end On_DidDeleteFiles_Notification;

   -------------------------------------
   -- Text_Document_Highlight_Request --
   -------------------------------------

   procedure Text_Document_Highlight_Request
     (Self    : in out Client'Class;
      Request : out LSP.Types.LSP_Number_Or_String;
      Value   : LSP.Messages.TextDocumentPositionParams)
   is
      Message : Highlight_Request := (params => Value, others => <>);
   begin
      Self.Send_Request
        (Request,
         "textDocument/documentHighlight",
         Decoders.Text_Document_Highlight_Response'Access,
         Message);
   end Text_Document_Highlight_Request;

   ---------------------------------
   -- Text_Document_Hover_Request --
   ---------------------------------

   procedure Text_Document_Hover_Request
     (Self    : in out Client'Class;
      Request : out LSP.Types.LSP_Number_Or_String;
      Value   : LSP.Messages.TextDocumentPositionParams)
   is
      Message : Hover_Request := (params => Value, others => <>);
   begin
      Self.Send_Request
        (Request,
         "textDocument/hover",
         Decoders.Text_Document_Hover_Response'Access,
         Message);
   end Text_Document_Hover_Request;

   -----------------------------------------
   -- Text_Document_Folding_Range_Request --
   -----------------------------------------

   procedure Text_Document_Folding_Range_Request
     (Self    : in out Client'Class;
      Request : out LSP.Types.LSP_Number_Or_String;
      Value   : LSP.Messages.FoldingRangeParams)
   is
      Message : Folding_Range_Request := (params => Value, others => <>);
   begin
      Self.Send_Request
        (Request,
         "textDocument/foldingRange",
         Decoders.Text_Document_Folding_Range_Response'Access,
         Message);
   end Text_Document_Folding_Range_Request;

   --------------------------------------
   -- Text_Document_References_Request --
   --------------------------------------

   procedure Text_Document_References_Request
     (Self    : in out Client'Class;
      Request : out LSP.Types.LSP_Number_Or_String;
      Value   : LSP.Messages.ReferenceParams)
   is
      Message : References_Request := (params => Value, others => <>);
   begin
      Self.Send_Request
        (Request,
         "textDocument/references",
         Decoders.Text_Document_References_Response'Access,
         Message);
   end Text_Document_References_Request;

   ------------------------------------------
   -- Text_Document_Signature_Help_Request --
   ------------------------------------------

   procedure Text_Document_Signature_Help_Request
     (Self    : in out Client'Class;
      Request : out LSP.Types.LSP_Number_Or_String;
      Value   : LSP.Messages.SignatureHelpParams)
   is
      Message : Signature_Help_Request := (params => Value, others => <>);
   begin
      Self.Send_Request
        (Request,
         "textDocument/signatureHelp",
         Decoders.Text_Document_Signature_Help_Response'Access,
         Message);
   end Text_Document_Signature_Help_Request;

   ----------------------------------
   -- Text_Document_Symbol_Request --
   ----------------------------------

   procedure Text_Document_Symbol_Request
     (Self    : in out Client'Class;
      Request : out LSP.Types.LSP_Number_Or_String;
      Value   : LSP.Messages.DocumentSymbolParams)
   is
      Message : Document_Symbols_Request := (params => Value, others => <>);
   begin
      Self.Send_Request
        (Request, "textDocument/documentSymbol",
         Decoders.Text_Document_Symbol_Response'Access,
         Message);
   end Text_Document_Symbol_Request;

   --------------------------
   -- Workspace_Apply_Edit --
   --------------------------

   procedure Workspace_Apply_Edit
     (Self    : in out Client'Class;
      Request : LSP.Types.LSP_Number_Or_String;
      Failure : LSP.Types.Optional_Virtual_String)
   is
      Message : LSP.Messages.Client_Responses.ApplyWorkspaceEdit_Response :=
        (Is_Error => False,
         result => (applied => not Failure.Is_Set,
                    failureReason => Failure,
                    failedChange => <>),
         error => (Is_Set => False),
         others => <>);
   begin
      Self.Send_Response (Request, Message);
   end Workspace_Apply_Edit;

   -------------------
   -- Void_Response --
   -------------------

   procedure Void_Response
     (Self    : in out Client'Class;
      Request : LSP.Types.LSP_Number_Or_String)
   is
      Ok : LSP.Messages.ResponseMessage :=
        (Is_Error => False,
         error    => (Is_Set => False),
         others   => <>);
   begin
      Self.Send_Response (Request, Ok);
   end Void_Response;

   ---------------------------------
   -- On_Initialized_Notification --
   ---------------------------------

   overriding procedure On_Initialized_Notification (Self : access Client) is
      Message : Initialized_Notification := (others => <>);
   begin
      Self.Send_Notification ("initialized", Message);
   end On_Initialized_Notification;

   --------------------------------------------
   -- On_DidChangeConfiguration_Notification --
   --------------------------------------------

   overriding procedure On_DidChangeConfiguration_Notification
     (Self  : access Client;
      Value : LSP.Messages.DidChangeConfigurationParams)
   is
      Message : DidChangeConfiguration_Notification :=
        (params => Value, others => <>);
   begin
      Self.Send_Notification ("workspace/didChangeConfiguration", Message);
   end On_DidChangeConfiguration_Notification;

   -----------------------------------------------
   -- On_DidChangeWorkspaceFolders_Notification --
   -----------------------------------------------

   overriding procedure On_DidChangeWorkspaceFolders_Notification
     (Self  : access Client;
      Value : LSP.Messages.DidChangeWorkspaceFoldersParams)
   is
      Message : DidChangeWorkspaceFolders_Notification :=
        (params => Value, others => <>);
   begin
      Self.Send_Notification ("workspace/didChangeWorkspaceFolders", Message);
   end On_DidChangeWorkspaceFolders_Notification;

   -------------------------------------------
   -- On_DidChangeWatchedFiles_Notification --
   -------------------------------------------

   overriding procedure On_DidChangeWatchedFiles_Notification
     (Self  : access Client;
      Value : LSP.Messages.DidChangeWatchedFilesParams)
   is
      Message : DidChangeWatchedFiles_Notification :=
        (params => Value, others => <>);
   begin
      Self.Send_Notification ("workspace/didChangeWatchedFiles", Message);
   end On_DidChangeWatchedFiles_Notification;

   ---------------------------------------
   -- Workspace_Execute_Command_Request --
   ---------------------------------------

   procedure Workspace_Execute_Command_Request
     (Self    : in out Client'Class;
      Request : out LSP.Types.LSP_Number_Or_String;
      Value   : LSP.Messages.ExecuteCommandParams)
   is
      Message : Execute_Command_Request := (params => Value, others => <>);
   begin
      Self.Send_Request
        (Request,
         "workspace/executeCommand",
         Decoders.Workspace_Execute_Command_Response'Access,
         Message);
   end Workspace_Execute_Command_Request;

   ------------------------------
   -- Workspace_Symbol_Request --
   ------------------------------

   procedure Workspace_Symbol_Request
     (Self    : in out Client'Class;
      Request : out LSP.Types.LSP_Number_Or_String;
      Value   : LSP.Messages.WorkspaceSymbolParams)
   is
      Message : Workspace_Symbols_Request := (params => Value, others => <>);
   begin
      Self.Send_Request
        (Request,
         "workspace/symbol",
         Decoders.Workspace_Symbol_Response'Access,
         Message);
   end Workspace_Symbol_Request;

end LSP.Clients;
