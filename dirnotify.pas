unit dirnotify;

interface

uses
Windows, Messages, SysUtils, Classes,
Graphics, Controls, Forms, Dialogs;

type
  EDirNotificationError = class(Exception);

  TDirNotify = class;
  TNotifyFilter = (nfFileName, nfDirName, nfAttributes, nfSize, nfLastWrite,nfSecurity);
  TNotifyFilters = set of TNotifyFilter;

  TNotificationThread = class(TThread)
  private
    Owner: TDirNotify;
  public
    constructor Create;
    destructor Destroy; override;
  protected
    procedure Execute; override;
  end;

  TDirNotify = class(TComponent)
  private
    FEnabled: Boolean;
    FOnChange: TNotifyEvent;
    FNotificationThread: TNotificationThread;
    FPath: String;
    FWatchSubTree: Boolean;
    FFilter: TNotifyFilters;
  private
    procedure SetEnabled( Value: Boolean );
    procedure SetOnChange( Value: TNotifyEvent );
    procedure SetPath( Value: String );
    procedure SetWatchSubTree( Value: Boolean );
    procedure SetFilter( Value: TNotifyFilters );
  private
    procedure RecreateThread;
  protected
    procedure Change;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property OnChange: TNotifyEvent read FOnChange write SetOnChange;
    property Path: String read FPath write SetPath;
    property WatchSubTree: Boolean read FWatchSubTree write SetWatchSubTree;
    property Filter: TNotifyFilters read FFilter write SetFilter default [nfFileName, nfDirName, nfAttributes, nfLastWrite, nfSecurity];
  end;

implementation

const
LASTERRORTEXTLENGTH = 500;

var
LastErrorText: array [0..LASTERRORTEXTLENGTH] of char;


function GetLastErrorText: PChar;
begin
FormatMessage( FORMAT_MESSAGE_FROM_SYSTEM,
nil, GetLastError, 0, LastErrorText, LASTERRORTEXTLENGTH, nil );
Result := LastErrorText;
end;


constructor TNotificationThread.Create;
begin
  inherited Create( True );
end;

destructor TNotificationThread.Destroy;
begin
  Terminate;
  Resume;
  WaitFor;

  inherited;
end;

procedure TNotificationThread.Execute;
var
  h: THandle;
  nf: Longint;
  wst: LongBool;
begin
    // 监听变化的类型
  nf := 0;
  if (nfFileName in Owner.Filter) then nf := FILE_NOTIFY_CHANGE_FILE_NAME;
  if (nfDirName in Owner.Filter) then nf := nf or FILE_NOTIFY_CHANGE_DIR_NAME;
  if (nfAttributes in Owner.Filter) then nf := nf or FILE_NOTIFY_CHANGE_ATTRIBUTES;
  if (nfSize in Owner.Filter) then nf := nf or FILE_NOTIFY_CHANGE_SIZE;
  if (nfLastWrite in Owner.Filter) then nf := nf or FILE_NOTIFY_CHANGE_LAST_WRITE;
  if (nfSecurity in Owner.Filter) then nf := nf or FILE_NOTIFY_CHANGE_SECURITY;

    // 是否监听子目录
  if Owner.FWatchSubTree then
    wst := Longbool(1)
  else
    wst := Longbool(0);

  try  // 开始监听
    h := FindFirstChangeNotification( Pointer(Owner.Path), wst, nf );
    if (h = INVALID_HANDLE_VALUE) then  // 无法开始监听
      Exit;
  except
    Exit;
  end;

  try   // 循环监听
    repeat
      if (WaitForSingleObject( h, 100 ) = WAIT_OBJECT_0) then
      begin
        Owner.Change;
        if not FindNextChangeNotification( h ) then  // 无法继续监听
          Break;
      end;
    until Terminated;
  except
  end;
end;


constructor TDirNotify.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFilter := [nfFileName, nfDirName];
  FEnabled := True;
  FWatchSubTree := False;
end;


destructor TDirNotify.Destroy;
begin
  FNotificationThread.Free;
  inherited;
end;

procedure TDirNotify.SetEnabled(Value: Boolean);
begin
  if Value <> FEnabled then
  begin
    FEnabled := Value;
    RecreateThread;
  end;
end;


procedure TDirNotify.SetPath( Value: String );
begin
  if Value <> FPath then
  begin
    FPath := Value;
    RecreateThread;
  end;
end;


procedure TDirNotify.SetWatchSubTree( Value: Boolean );
begin
  if Value <> FWatchSubTree then
  begin
    FWatchSubTree := Value;
    RecreateThread;
  end;
end;


procedure TDirNotify.SetFilter( Value: TNotifyFilters );
begin
  if Value <> FFilter then
  begin
    FFilter := Value;
    RecreateThread;
  end;
end;


procedure TDirNotify.SetOnChange(Value: TNotifyEvent);
begin
  FOnChange := Value;
end;


procedure TDirNotify.Change;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;


procedure TDirNotify.RecreateThread;
begin
  // destroy thread
  FNotificationThread.Free;
  FNotificationThread := nil;

  if FEnabled and (FPath <> '') then
  begin
    // create thread
    FNotificationThread := TNotificationThread.Create;
    FNotificationThread.Owner := self;
    FNotificationThread.Resume;
  end;
end;

end.
