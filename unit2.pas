unit Unit2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Unit1;

type

  { TForm2 }

  TForm2 = class(TForm)
    Button1: TButton;
    Label3: TLabel;
    port: TEdit;
    url: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public

  end;

var
  Form2: TForm2;

implementation

{$R *.lfm}

{ TForm2 }

procedure TForm2.Button1Click(Sender: TObject);
begin
  Form1.jsonprop.StoredValue['port'] := port.Text;
  Form1.jsonprop.StoredValue['url'] := url.Text;
  Form1.jsonprop.Save;

  Form2.Hide;
end;

procedure TForm2.FormShow(Sender: TObject);
begin
  port.Text := Form1.jsonprop.ReadInteger('port', 4444).ToString;
  url.Text := Form1.jsonprop.ReadString('url', '127.0.0.1');
end;

end.

