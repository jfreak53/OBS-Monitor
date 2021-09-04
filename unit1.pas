unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Menus, JSONPropStorage, wsutils, wsmessages, wsstream, ssockets,
  WebsocketsClient, fpjson, jsonparser;

type

  { TForm1 }

  TForm1 = class(TForm)
    jsonprop: TJSONPropStorage;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    Panel1: TPanel;
    PopupMenu1: TPopupMenu;
    Shape1: TShape;
    Shape2: TShape;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure Panel1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Panel1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer
      );
    procedure Panel1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure changeMonIndex(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    FCommunicator: TWebsocketCommunicator;
    XPos, YPos: Integer;
    Moving: Boolean;
    start: integer;
    procedure ReceiveMessage(Sender: TObject);
    procedure StreamClosed(Sender: TObject);
    procedure ComConnect();
  public
    destructor Destroy; override;
  end;

  TMenuItemExtended = class(TMenuItem)
  private
    fValue: string;
  published
    property Value: string read fValue write fValue;
  end;

var
  Form1: TForm1;

implementation
uses Unit2;

{$R *.lfm}

{ TForm1 }

procedure TForm1.changeMonIndex(Sender: TObject);
var
  I: integer;
begin
  with Sender as TMenuItemExtended do
  begin
    for I := 0 to MenuItem2.Count - 1 do
    begin
      MenuItem2.Items[I].Checked := False;
    end;
    Checked := True;
    Form1.Top := 0;
    Form1.Left := Screen.Monitors[StrToInt(Value)].Left;
    Form1.Width := Screen.Monitors[StrToInt(Value)].Width;
    //jsonprop.WriteInteger('monitor', StrToInt(Value));
    jsonprop.StoredValue['monitor'] := Value;
    jsonprop.StoredValue['top'] := Form1.Top.ToString;
    jsonprop.StoredValue['left'] := Form1.Left.ToString;
  end;

  jsonprop.Save;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Label13.Caption := Format('Connect In: %d seconds', [start]);
  Label13.Visible := True;
  Dec(start);
  if (start < 0) then begin
    Timer1.Enabled := False;
    Label13.Visible := False;
    ComConnect();
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  mons, I, mon, topm, leftm, port: Integer;
  menui: TMenuItemExtended;
  url: String;
begin
  mon := jsonprop.ReadInteger('monitor', 0);
  topm := jsonprop.ReadInteger('top', 0);
  leftm := jsonprop.ReadInteger('left', 0);
  port := jsonprop.ReadInteger('port', 4444);
  url := jsonprop.ReadString('url', '127.0.0.1');
  jsonprop.StoredValue['top'] := topm.ToString;
  jsonprop.StoredValue['left'] := leftm.ToString;
  jsonprop.StoredValue['monitor'] := mon.ToString;
  jsonprop.StoredValue['port'] := port.ToString;
  jsonprop.StoredValue['url'] := url;

  mons := Screen.MonitorCount;
  for I := 0 to mons-1 do
    begin
      menui := TMenuItemExtended.Create(PopupMenu1);

      menui.Caption := 'Monitor '+IntToStr(I+1);
      menui.Value := IntToStr(I);
      menui.OnClick := @changeMonIndex;
      if I = mon then menui.Checked := true;
      MenuItem2.Insert(I, menui);
    end;
  {if mons > 0 then mons := mons-1;}

  Form1.Top := topm;
  Form1.Left := leftm;//Screen.Monitors[mon].Left;
  Form1.Width := Screen.Monitors[mon].Width;

  start := 5;
  Timer1.Enabled := True;
  MenuItem5.Enabled := True;

  jsonprop.Save;
end;

procedure TForm1.ComConnect();
var
  client: TWebsocketClient;
  port: Integer;
  url: String;
begin
  port := jsonprop.ReadInteger('port', 4444);
  url := jsonprop.ReadString('url', '127.0.0.1');

  client := TWebsocketClient.Create(url, port);
  try
    try
      FCommunicator := client.Connect(TSocketHandler.Create);
      FCommunicator.OnClose := @StreamClosed;
      FCommunicator.OnReceiveMessage := @ReceiveMessage;
      FCommunicator.StartReceiveMessageThread;
      Label12.Caption := 'Online';
      Label12.Font.Color := clGreen;
      MenuItem5.Enabled := False;
    except
      //ShowMessage('Except1');
      start := 10;
      Timer1.Enabled := True;
    end;
  except
    //ShowMessage('Except2');
    client.Free;
    start := 10;
    Timer1.Enabled := True;
  end;
end;

procedure TForm1.MenuItem1Click(Sender: TObject);
begin
  Form2.Show;
end;

procedure TForm1.MenuItem3Click(Sender: TObject);
begin
  Form1.Top := 0;
  Form1.Left := Screen.Monitors[jsonprop.StoredValue['monitor'].ToInteger].Left;

  jsonprop.StoredValue['top'] := Form1.Top.ToString;
  jsonprop.StoredValue['left'] := Form1.Left.ToString;
  jsonprop.Save;
end;

procedure TForm1.MenuItem4Click(Sender: TObject);
begin
  Form1.Close;
end;

procedure TForm1.MenuItem5Click(Sender: TObject);
begin
  Timer1.Enabled := False;
  Label13.Visible := False;
  ComConnect();
end;

procedure TForm1.Panel1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  XPos := X;
  YPos := Y;
  Moving := True;
end;

procedure TForm1.Panel1MouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  If Moving then Form1.Left := Form1.Left+X-XPos;
  If Moving then Form1.Top := Form1.Top+Y-YPos;
end;

procedure TForm1.Panel1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Moving := False;
  //jsonprop.WriteInteger('monitor', Form1.Monitor.MonitorNum);
  //jsonprop.WriteInteger('top', Form1.Top);
  //jsonprop.WriteInteger('left', Form1.Left);

  jsonprop.StoredValue['monitor'] := Form1.Monitor.MonitorNum.ToString;
  jsonprop.StoredValue['top'] := Form1.Top.ToString;
  jsonprop.StoredValue['left'] := Form1.Left.ToString;
  jsonprop.Save;
end;

procedure TForm1.StreamClosed(Sender: TObject);
begin
  //ShowMessage('Connection to '+ FCommunicator.SocketStream.RemoteAddress.Address+ ' closed');
  //ShowMessage('Except3');
  MenuItem5.Enabled := True;
  Label12.Caption := 'Offline';
  Label12.Font.Color := clRed;
  //start := 10;
  //Timer1.Interval := 1000;
  //Timer1.Enabled := True;
  //Button1.Click;
  Timer1.Enabled := False;
  Label13.Visible := False;
  ComConnect();
end;

procedure TForm1.ReceiveMessage(Sender: TObject);
var
  MsgList: TWebsocketMessageOwnerList;
  m: TWebsocketMessage;
  J: TJSONData;
begin
  MsgList := TWebsocketMessageOwnerList.Create(True);
  try
    FCommunicator.GetUnprocessedMessages(MsgList);
    for m in MsgList do
      if m is TWebsocketStringMessage then
      begin
        J := GetJSON(TWebsocketStringMessage(m).Data);
        if J.FindPath('update-type').AsString = 'RecordingStarted' then
        begin
          Label1.Caption := 'Recording On';
          Shape1.Brush.Color := clRed;
        end
        else if J.FindPath('update-type').AsString = 'RecordingStopped' then
        begin
          Label1.Caption := 'Recording Off';
          Shape1.Brush.Color := clWhite;
        end;

        if J.FindPath('update-type').AsString = 'StreamStarted' then
        begin
          Label2.Caption := 'Streaming On';
          Shape2.Brush.Color := clRed;
        end
        else if J.FindPath('update-type').AsString = 'StreamStopped' then
        begin
          Label2.Caption := 'Streaming Off';
          Shape2.Brush.Color := clWhite;
        end;

        if J.FindPath('update-type').AsString = 'StreamStatus' then
        begin
          Label4.Caption := J.FindPath('kbits-per-sec').AsString;
          Label6.Caption := J.FindPath('num-dropped-frames').AsString;
          Label8.Caption := J.FindPath('stream-timecode').AsString;
          Label10.Caption := J.FindPath('rec-timecode').AsString;
        end;

        {ShowMessage('Message from '+ FCommunicator.SocketStream.RemoteAddress.Address+ ': '+ TWebsocketStringMessage(m).Data);}
      end;
      {else if m is TWebsocketPongMessage then
        ShowMessage('Pong from '+ FCommunicator.SocketStream.RemoteAddress.Address+ ': '+ TWebsocketPongMessage(m).Data);}
  finally
    MsgList.Free;
  end;
end;

destructor TForm1.Destroy;
begin
  FCommunicator.StopReceiveMessageThread;
  while FCommunicator.ReceiveMessageThreadRunning do
    Break;
  FCommunicator.Free;
  inherited Destroy;
end;

end.

