unit UFileThread;

interface

uses UThreadUtil, IOUtils, classes, SysUtils, Math, shellapi, SyncObjs;

type

{$Region ' 文件 Job 信息 ' }

    // 父类
  TFileJobBase = class( TThreadJob )
  public
    ActionID : string;
    ControlPath : string;
    IsLocal : Boolean;
  public
    constructor Create( _ActionID : string );
    procedure SetControlPath( _ControlPath : string; _IsLocal : Boolean );
    procedure Update;override;
  protected
    procedure BeforeAction;
    procedure ActionHandle;virtual;abstract;
    procedure AfterAction;
  private
    procedure RemoveToFace;
  end;

    // 文件父类
  TFileJob = class( TFileJobBase )
  public
    FilePath : string;
  public
    procedure SetFilePath( _FilePath : string );
  end;

    // 有目标的 Job
  TFileDesJob = class( TFileJob )
  public
    DesFilePath : string;
  public
    procedure SetDesFilePath( _DesFilePath : string );
  end;

    // 复制
  TFileCopyJob = class( TFileDesJob )
  protected
    procedure ActionHandle;override;
  private
    procedure AddToFace;
  end;

    // 删除
  TFileDeleteJob = class( TFileJob )
  protected
    procedure ActionHandle;override;
  private
    procedure AddToFace;
  end;

    // 压缩
  TFileZipJob = class( TFileJobBase )
  public
    FileList : TStringList;
    ZipPath : string;
  public
    procedure SetFileList( _FileList : TStringList );
    procedure SetZipPath( _ZipPath : string );
    destructor Destroy; override;
  protected
    procedure ActionHandle;override;
  private
    procedure ShowForm;
    procedure HideForm;
  private
    procedure AddToFace;
  end;

{$EndRegion}

    // 添加参数
  TJobAddParams = record
  public
    FilePath, DesFilePath : string;
    ControlPath, ActionID : string;
    IsLocal : Boolean;
  end;

    // 删除参数
  TJobDeleteParams = record
  public
    FilePath : string;
    ControlPath, ActionID : string;
    IsLocal : Boolean;
  end;

    // 压缩参数
  TJobZipParams = record
  public
    FileList : TStringList;
    ZipPath : string;
    ControlPath, ActionID : string;
    IsLocal : Boolean;
  end;

    // 文件任务处理器
  TMyFileJobHandler = class( TMyJobHandler )
  private
    RunningLock : TCriticalSection;
    RunningCount : Integer;
  private
    IsUserStop : Boolean;
  public
    constructor Create;
    destructor Destroy; override;
  public
    procedure AddFleCopy( Params : TJobAddParams );
    procedure AddFleDelete( Params : TJobDeleteParams );
    procedure AddFileZip( Params : TJobZipParams );
  public
    procedure AddRuningCount;
    procedure RemoveRuningCount;
    function ReadIsRunning : Boolean;
  end;

var
  MyFileJobHandler : TMyFileJobHandler;

implementation

uses UMyUtils, UFrameDriver, UFormZip;

{ TFileMoveInfo }

procedure TFileJobBase.AfterAction;
begin
    // 正在运行
  MyFileJobHandler.RemoveRuningCount;
end;

procedure TFileJobBase.BeforeAction;
begin
    // 结束 Waiting
  FaceUpdate( RemoveToFace );
end;

constructor TFileJobBase.Create(_ActionID: string);
begin
  ActionID := _ActionID;
end;

procedure TFileJobBase.RemoveToFace;
begin
  FaceFileJobApi.RemoveFileJob( ActionID );
end;

procedure TFileJobBase.SetControlPath(_ControlPath: string;
  _IsLocal : Boolean);
begin
  ControlPath := _ControlPath;
  IsLocal := _IsLocal;
end;

{ TFileDesJob }

procedure TFileDesJob.SetDesFilePath(_DesFilePath: string);
begin
  DesFilePath := _DesFilePath;
end;

{ TFileCopyJob }

procedure TFileCopyJob.ActionHandle;
var
  fo: TSHFILEOPSTRUCT;
begin
  FillChar(fo, SizeOf(fo), 0);
  with fo do
  begin
    Wnd := 0;
    wFunc := FO_COPY;
    pFrom := PChar(FilePath + #0);
    pTo := PChar(DesFilePath + #0);
    fFlags := FOF_NOCONFIRMATION + FOF_NOCONFIRMMKDIR;
  end;
  if SHFileOperation(fo)=0 then
    FaceUpdate( AddToFace )
  else
    MyFileJobHandler.IsUserStop := True;
end;

procedure TFileCopyJob.AddToFace;
begin
  if IsLocal then
    UserNetworkDriverApi.AddFile( ControlPath, DesFilePath )
  else
    UserLocalDriverApi.AddFile( ControlPath, DesFilePath );
end;

{ TMyFileJobHandler }

procedure TMyFileJobHandler.AddFileZip(Params : TJobZipParams);
var
  FileZipJob : TFileZipJob;
begin
  AddRuningCount;

  FileZipJob := TFileZipJob.Create( Params.ActionID );
  FileZipJob.SetControlPath( Params.ControlPath, Params.IsLocal );
  FileZipJob.SetFileList( Params.FileList );
  FileZipJob.SetZipPath( Params.ZipPath );
  AddJob( FileZipJob );
end;

procedure TMyFileJobHandler.AddFleCopy( Params : TJobAddParams );
var
  FileCopyJob : TFileCopyJob;
begin
  AddRuningCount;

  FileCopyJob := TFileCopyJob.Create( Params.ActionID );
  FileCopyJob.SetControlPath( Params.ControlPath, Params.IsLocal );
  FileCopyJob.SetFilePath( Params.FilePath );
  FileCopyJob.SetDesFilePath( Params.DesFilePath );
  AddJob( FileCopyJob );
end;

procedure TMyFileJobHandler.AddFleDelete(Params : TJobDeleteParams);
var
  FileDeleteJob : TFileDeleteJob;
begin
  AddRuningCount;

  FileDeleteJob := TFileDeleteJob.Create( Params.ActionID );
  FileDeleteJob.SetControlPath( Params.ControlPath, Params.IsLocal );
  FileDeleteJob.SetFilePath( Params.FilePath );
  AddJob( FileDeleteJob );
end;

procedure TMyFileJobHandler.AddRuningCount;
begin
  RunningLock.Enter;
  Inc( RunningCount );
  RunningLock.Leave;
end;

constructor TMyFileJobHandler.Create;
begin
  inherited;
  RunningLock := TCriticalSection.Create;
  RunningCount := 0;
  IsUserStop := False;
end;

destructor TMyFileJobHandler.Destroy;
begin
  RunningLock.Free;
  inherited;
end;

function TMyFileJobHandler.ReadIsRunning: Boolean;
begin
  RunningLock.Enter;
  Result := RunningCount > 0;
  RunningLock.Leave;
end;

procedure TMyFileJobHandler.RemoveRuningCount;
begin
  RunningLock.Enter;
  Dec( RunningCount );
  RunningLock.Leave;

    // Reset
  if RunningCount <= 0 then
    IsUserStop := False;
end;

procedure TFileJobBase.Update;
begin
    // 操作前
  BeforeAction;

  try   // 实际操作
    if not MyFileJobHandler.IsUserStop then
      ActionHandle;
  except
  end;

    // 操作后
  AfterAction;
end;

{ TFileDeleteJob }

procedure TFileDeleteJob.ActionHandle;
begin
  if MyShellFile.DeleteFile( FilePath ) then
    FaceUpdate( AddToFace )
  else
    MyFileJobHandler.IsUserStop := True;
end;

procedure TFileDeleteJob.AddToFace;
begin
  if IsLocal then
    UserLocalDriverApi.RemoveFile( ControlPath, FilePath )
  else
    UserNetworkDriverApi.RemoveFile( ControlPath, FilePath );
end;

{ TFileJob }

procedure TFileJob.SetFilePath(_FilePath: string);
begin
  FilePath := _FilePath;
end;

{ TFileZipBaseJob }

procedure TFileZipJob.ActionHandle;
begin
  FaceUpdate( ShowForm );

  frmZip.SetFileList( FileList );
  frmZip.SetZipPath( ZipPath );
  if frmZip.FileZip then
    FaceUpdate( AddToFace )
  else  // 压缩失败，删除压缩文件
    MyShellFile.DeleteFile( ZipPath );

  FaceUpdate( HideForm );
end;

procedure TFileZipJob.AddToFace;
begin
  if IsLocal then
  begin
    UserLocalDriverApi.CancelSelect( ControlPath );
    UserLocalDriverApi.AddFile( ControlPath, ZipPath );
  end
  else
  begin
    UserNetworkDriverApi.CancelSelect( ControlPath );
    UserNetworkDriverApi.AddFile( ControlPath, ZipPath );
  end;
end;

destructor TFileZipJob.Destroy;
begin
  FileList.Free;
  inherited;
end;

procedure TFileZipJob.HideForm;
begin
  frmZip.Close;
end;

procedure TFileZipJob.SetFileList(_FileList: TStringList);
begin
  FileList := _FileList;
end;

procedure TFileZipJob.SetZipPath(_ZipPath: string);
begin
  ZipPath := _ZipPath;
end;

procedure TFileZipJob.ShowForm;
begin
  frmZip.Show;
end;


end.
