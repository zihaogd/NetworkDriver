unit UFileWatchThread;

interface

uses classes, dirnotify, ExtCtrls;

type

    // 文件变化监听
  TFileWatchThread = class( TThread )
  private
    ControlPath : string;
    LocalPath, NetworkPath : string;
  private
    LocalDirNotify : TDirNotify;  // 目录监听器
    Timer : TTimer;
  public
    constructor Create;
    procedure SetPath( _ControlPath, _LocalPath, _NetworkPath : string );
    procedure SetLocalPath( _LocalPath : string );
    procedure SetNetworkPath( _NetworkPath : string );
    destructor Destroy; override;
  protected
    procedure Execute; override;
  private
    procedure LocalFolderChange(Sender: TObject);
    procedure NetworkFolderChange;
  private
    procedure OnTime( Sender: TObject );
  end;

    // 文件监听对象
  TMyFileWatch = class
  public
    IsStop : Boolean;
    FileWatchThread : TFileWatchThread;
  public
    constructor Create;
    procedure Stop;
  public
    procedure SetPath( ControlPath, LocalPath, NetworkPath : string );
    procedure SetLocalPath( LocalPath : string );
    procedure SetNetworkPath( NetworkPath : string );
  end;

var
  MyFileWatch : TMyFileWatch;

implementation

uses UMyUtils, SysUtils, UMyFaceThread;

{ TFileWatchThread }

constructor TFileWatchThread.Create;
begin
  inherited Create( True );
  LocalPath := '';
  NetworkPath := '';
  LocalDirNotify := TDirNotify.Create( nil );
  LocalDirNotify.OnChange := LocalFolderChange;
  Timer := TTimer.Create( nil );
  Timer.Enabled := False;
  Timer.Interval := 1000;
  Timer.OnTimer := OnTime;
end;

destructor TFileWatchThread.Destroy;
begin
  Terminate;
  Resume;
  WaitFor;
  LocalDirNotify.Free;
  Timer.Free;
  inherited;
end;

procedure TFileWatchThread.Execute;
var
  i: Integer;
begin
  while not Terminated do
  begin
    for i := 1 to 100 do  // 10 秒刷新一次
    begin
      if Terminated then
        Break;
      Sleep(100);
    end;
    if NetworkPath <> '' then // 刷新
      NetworkFolderChange;
  end;
end;

procedure TFileWatchThread.LocalFolderChange(Sender: TObject);
begin
  Timer.Enabled := False;
  Timer.Enabled := True;
end;

procedure TFileWatchThread.NetworkFolderChange;
begin
  MyFaceJobHandler.FileChange( ControlPath, NetworkPath, False );
end;

procedure TFileWatchThread.OnTime(Sender: TObject);
begin
  MyFaceJobHandler.FileChange( ControlPath, LocalPath, True );
end;

procedure TFileWatchThread.SetLocalPath(_LocalPath: string);
begin
  LocalPath := _LocalPath;

  TThread.CreateAnonymousThread(
  procedure
  begin
    if ( LocalPath <> '' ) and MyFilePath.getIsFixedDriver( ExtractFileDrive( LocalPath ) ) then
    begin
      LocalDirNotify.Path := LocalPath;
      LocalDirNotify.Enabled := True;
    end
    else
      LocalDirNotify.Enabled := False;
  end).Start;
end;

procedure TFileWatchThread.SetNetworkPath(_NetworkPath: string);
begin
  NetworkPath := _NetworkPath;
end;

procedure TFileWatchThread.SetPath(_ControlPath, _LocalPath,
  _NetworkPath: string);
begin
  ControlPath := _ControlPath;
  SetLocalPath( _LocalPath );
  SetNetworkPath( _NetworkPath );
end;

{ TMyFileWatch }

constructor TMyFileWatch.Create;
begin
  FileWatchThread := TFileWatchThread.Create;
  FileWatchThread.Resume;
  IsStop := False;
end;

procedure TMyFileWatch.SetLocalPath(LocalPath: string);
begin
  if IsStop then
    Exit;
  FileWatchThread.SetLocalPath( LocalPath );
end;

procedure TMyFileWatch.SetNetworkPath(NetworkPath: string);
begin
  if IsStop then
    Exit;
  FileWatchThread.SetNetworkPath( NetworkPath );
end;

procedure TMyFileWatch.SetPath(ControlPath, LocalPath, NetworkPath : string);
begin
  if IsStop then
    Exit;
  FileWatchThread.SetPath( ControlPath, LocalPath, NetworkPath );
end;

procedure TMyFileWatch.Stop;
begin
  IsStop := True;
  FileWatchThread.Free;
end;

end.
