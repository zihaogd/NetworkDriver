unit UFormAbout;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons;

type
  TfrmAbout = class(TForm)
    Image1: TImage;
    lbAppName: TLabel;
    lbEdition: TLabel;
    lbHomePage: TLinkLabel;
    plEmail: TPanel;
    btnEmail: TSpeedButton;
    Label3: TLabel;
    lbCopyCompleted: TLabel;
    procedure lbEmailMouseEnter(Sender: TObject);
    procedure btnEmailMouseLeave(Sender: TObject);
    procedure btnEmailClick(Sender: TObject);
    procedure lbCopyCompletedMouseLeave(Sender: TObject);
    procedure lbHomePageLinkClick(Sender: TObject; const Link: string;
      LinkType: TSysLinkType);
    procedure FormCreate(Sender: TObject);
    procedure plEmailMouseEnter(Sender: TObject);
  private
    function ReadAppEdition : string;
  public
    { Public declarations }
  end;

var
  frmAbout: TfrmAbout;

implementation

uses Clipbrd, UMyUtils;

{$R *.dfm}

procedure TfrmAbout.btnEmailClick(Sender: TObject);
var
  EmailStr : string;
begin
  plEmail.Caption := '';
  lbCopyCompleted.Visible := True;
  btnEmail.Visible := False;

    // ¸´ÖÆ
  EmailStr := 'purplewindsoftware@gmail.com';
  Clipboard.AsText := EmailStr;
end;

procedure TfrmAbout.btnEmailMouseLeave(Sender: TObject);
begin
  btnEmail.Visible := False;
end;

procedure TfrmAbout.FormCreate(Sender: TObject);
begin
  lbEdition.Caption := ReadAppEdition;
end;

procedure TfrmAbout.lbCopyCompletedMouseLeave(Sender: TObject);
begin
  plEmail.Caption := btnEmail.Caption;
  lbCopyCompleted.Visible := False;
end;

procedure TfrmAbout.lbEmailMouseEnter(Sender: TObject);
begin
  btnEmail.Visible := True;
end;

procedure TfrmAbout.lbHomePageLinkClick(Sender: TObject; const Link: string;
  LinkType: TSysLinkType);
begin
  MyInternetExplorer.OpenWeb( 'www.purplewind.pw' );
end;

procedure TfrmAbout.plEmailMouseEnter(Sender: TObject);
begin
  btnEmail.Visible := True;
end;

function TfrmAbout.ReadAppEdition: string;
var
  InfoSize, Wnd: DWORD;
  VerBuf: Pointer;
  szName: array[0..255] of Char;
  Value: Pointer;
  Len: UINT;
  TransString:string;
begin
  InfoSize := GetFileVersionInfoSize(PChar(Application.ExeName), Wnd);
  if InfoSize <> 0 then
  begin
    GetMem(VerBuf, InfoSize);
    try
      if GetFileVersionInfo(PChar(Application.ExeName), Wnd, InfoSize, VerBuf) then
      begin
        Value :=nil;
        VerQueryValue(VerBuf, '\VarFileInfo\Translation', Value, Len);
        if Value <> nil then
           TransString := IntToHex(MakeLong(HiWord(Longint(Value^)), LoWord(Longint(Value^))), 8);
        Result := '';
        StrPCopy(szName, '\StringFileInfo\'+Transstring+'\FileVersion');
        if VerQueryValue(VerBuf, szName, Value, Len) then
           Result := StrPas(PChar(Value));
      end;
    except
    end;
    FreeMem(VerBuf);
  end;
end;

end.
