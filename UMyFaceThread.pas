unit UMyFaceThread;

interface

uses UThreadUtil, classes, StrUtils, UFileSearch, IOUtils, Types, SysUtils, IniFiles;

type

{$Region ' 共享窗口 ' }

    // 刷新网络计算机
  TNetworkComputerRefresh = class( TThreadJob )
  private
    NetworkPcList : TStringList;
  public
    constructor Create;
    procedure Update;override;
    destructor Destroy; override;
  private
    procedure FindNetworkPcList;
    procedure ShowNetworkPcList;
  end;

    // 刷新计算机共享目录
  TNetowrkFolderRefresh = class( TThreadJob )
  private
    ComputerName : string;
    NetworkFolderList : TStringList;
  public
    constructor Create( _ComputerName : string );
    procedure Update;override;
    destructor Destroy; override;
  private
    procedure ClearOldFolderList;
    procedure FindNetworkFolderList;
    procedure ShowNetworkFolderList;
  end;

{$EndRegion}

{$Region ' 文件窗口 ' }

    // 本地文件系统
  TLocalDriverRefresh = class( TThreadJob )
  private
    ControlPath : string;
  private
    FolderPath : string;
    FileList : TFileList;
  public
    constructor Create( _FolderPath : string );
    procedure SetControlPath( _ControlPath : string );
    procedure Update;override;
    destructor Destroy; override;
  private
    procedure FindDriverList;
    procedure FindFileList;
    procedure ReadHistoryList;
    procedure ShowFileList;
  private
    function ReadIsMyComputer : Boolean;
    procedure MoveFile( FileName : string );
  end;

    // 网络文件系统
  TNetworkDriverRefresh = class( TThreadJob )
  private
    ControlPath : string;
  private
    FolderPath : string;
    FileList : TFileList;
  public
    constructor Create( _FolderPath : string );
    procedure SetControlPath( _ControlPath : string );
    procedure Update;override;
    destructor Destroy; override;
  private
    procedure FindFileList;
    procedure ReadHistoryList;
    procedure ShowFileList;
  private
    procedure MoveFile( FileName : string );
  end;

    // 记录 文件列表的选择
  TFileListMarkSelectJob = class( TThreadJob )
  private
    FolderPath, SelectName : string;
  public
    constructor Create( _FolderPath, _SelectName : string );
    procedure Update;override;
  end;

    // 选中文件
  TFileListSelectJob = class( TThreadJob )
  private
    ControlPath, FilePath : string;
    IsLocal : Boolean;
  public
    constructor Create( _ControlPath, _FilePath : string );
    procedure SetIsLocal( _IsLocal : Boolean );
    procedure Update;override;
  private
    procedure SelectPath;
  end;

    // 目录变化 Job
  TFolderChangeNofityJob = class( TThreadJob )
  private
    FolderPath : string;
    OldFileList, NewFileList : TStringList;
    FileName : string;
  private
    ControlPath : string;
    IsLocal : Boolean;
  public
    constructor Create( _FolderPath : string );
    procedure SetControlPath( _ControlPath : string; _IsLocal : Boolean );
    procedure Update;override;
    destructor Destroy; override;
  private
    procedure ReadOldFileList;
    procedure ReadNewFileList;
  private
    procedure AddFile;
    procedure RemoveFile;
  end;

{$EndRegion}

    // 界面更新 Job
  TMyFaceJobHandler = class( TMyJobHandler )
  public
    procedure RefreshNetworkPc; // 刷新网上邻居
    procedure RefreshNetworkFolder( PcName : string ); // 刷新共享目录
  public
    procedure RefreshLocalDriver( FolderPath, ControlPath : string );  // 本地目录
    procedure RefreshNetworkDriver( FolderPath, ControlPath : string );  // 共享目录
    procedure FileListMarkSelect( FolderPath, SelectName : string );  // 记录选择位置
    procedure FileListSelect( ControlPath, FilePath : string; IsLocal : Boolean );  // 选择位置
    procedure FileChange( ControlPath, FolderPath : string; IsLocal : Boolean ); // 文件变化检测
  end;

var
  MyFaceJobHandler : TMyFaceJobHandler;

implementation

uses UFormSelectShare, UMainForm, UFrameDriver, UMyUtils;

{ TNetworkComputerRefresh }

constructor TNetworkComputerRefresh.Create;
begin
  NetworkPcList := TStringList.Create;
end;

destructor TNetworkComputerRefresh.Destroy;
begin
  NetworkPcList.Free;
  inherited;
end;

procedure TNetworkComputerRefresh.FindNetworkPcList;
var
  GroupList, ComputerList, InputList : TStringList;
  i, j: Integer;
begin
    // 搜网上邻居
  GroupList := NetworkDriverUtil.ReadGroupList;
  for i := 0 to GroupList.Count - 1 do
  begin
    ComputerList := NetworkDriverUtil.ReadGroupPcList( GroupList[i] );
    for j := 0 to ComputerList.Count - 1 do
      NetworkPcList.Add( ComputerList[j] );
    ComputerList.Free;
  end;
  GroupList.Free;

    // 手工输入的 Pc
  InputList := frmSelectShare.ReadInputList;
  for i := 0 to InputList.Count - 1 do
    NetworkPcList.Add( InputList[i] );
end;

procedure TNetworkComputerRefresh.ShowNetworkPcList;
var
  i: Integer;
begin
    // 清空 旧Pc
  FaceNetworkPcApi.ClearComputer;

    // 添加 新计算机
  FaceNetworkPcApi.AddNewComputer;

    // 添加搜索的计算机
  for i := 0 to NetworkPcList.Count - 1 do
    FaceNetworkPcApi.AddComputer( NetworkPcList[i] );
end;

procedure TNetworkComputerRefresh.Update;
begin
    // 寻找 Pc
  FindNetworkPcList;

    // 显示 Pc
  FaceUpdate( ShowNetworkPcList );
end;

{ TMyFaceJobHandler }

procedure TMyFaceJobHandler.FileChange(ControlPath, FolderPath: string;
  IsLocal: Boolean);
var
  FolderChangeNofityJob : TFolderChangeNofityJob;
begin
  FolderChangeNofityJob := TFolderChangeNofityJob.Create( FolderPath );
  FolderChangeNofityJob.SetControlPath( ControlPath, IsLocal );
  AddJob( FolderChangeNofityJob );
end;


procedure TMyFaceJobHandler.FileListMarkSelect(FolderPath, SelectName: string);
var
  FileListMarkSelectJob : TFileListMarkSelectJob;
begin
  FileListMarkSelectJob := TFileListMarkSelectJob.Create( FolderPath, SelectName );
  AddJob( FileListMarkSelectJob );
end;

procedure TMyFaceJobHandler.FileListSelect(ControlPath, FilePath: string;
  IsLocal : Boolean);
var
  FileListSelectJob : TFileListSelectJob;
begin
  FileListSelectJob := TFileListSelectJob.Create( ControlPath, FilePath );
  FileListSelectJob.SetIsLocal( IsLocal );
  AddJob( FileListSelectJob );
end;

procedure TMyFaceJobHandler.RefreshLocalDriver(FolderPath, ControlPath: string);
var
  LocalDriverRefresh : TLocalDriverRefresh;
begin
  LocalDriverRefresh := TLocalDriverRefresh.Create( FolderPath );
  LocalDriverRefresh.SetControlPath( ControlPath );
  AddJob( LocalDriverRefresh );
end;

procedure TMyFaceJobHandler.RefreshNetworkDriver(FolderPath,
  ControlPath: string);
var
  NetworkDriverRefresh : TNetworkDriverRefresh;
begin
  NetworkDriverRefresh := TNetworkDriverRefresh.Create( FolderPath );
  NetworkDriverRefresh.SetControlPath( ControlPath );
  AddJob( NetworkDriverRefresh );
end;

procedure TMyFaceJobHandler.RefreshNetworkFolder(PcName: string);
var
  NetowrkFolderRefresh : TNetowrkFolderRefresh;
begin
  NetowrkFolderRefresh := TNetowrkFolderRefresh.Create( PcName );
  AddJob( NetowrkFolderRefresh );
end;

procedure TMyFaceJobHandler.RefreshNetworkPc;
var
  NetworkComputerRefresh : TNetworkComputerRefresh;
begin
  NetworkComputerRefresh := TNetworkComputerRefresh.Create;
  AddJob( NetworkComputerRefresh );
end;

{ TNetowrkFolderRefresh }

procedure TNetowrkFolderRefresh.ClearOldFolderList;
begin
    // 清空旧信息
  FaceNetworkFolderApi.Clear;
end;

constructor TNetowrkFolderRefresh.Create(_ComputerName: string);
begin
  ComputerName := _ComputerName;
  NetworkFolderList := TStringList.Create;
end;

destructor TNetowrkFolderRefresh.Destroy;
begin
  NetworkFolderList.Free;
  inherited;
end;

procedure TNetowrkFolderRefresh.FindNetworkFolderList;
var
  ShareList : TStringList;
  i: Integer;
begin
    // 网上邻居路径修正
  if LeftStr( ComputerName, 2 ) <> '\\' then
    ComputerName := '\\' + ComputerName;

    // 搜索
  ShareList := NetworkDriverUtil.ReadPcShareList( ComputerName );
  for i := 0 to ShareList.Count - 1 do
    NetworkFolderList.Add( ShareList[i] );
  ShareList.Free;
end;

procedure TNetowrkFolderRefresh.ShowNetworkFolderList;
var
  i: Integer;
begin
    // 添加新信息
  for i := 0 to NetworkFolderList.Count - 1 do
    FaceNetworkFolderApi.Add( NetworkFolderList[i] );
end;

procedure TNetowrkFolderRefresh.Update;
begin
    // 清空旧信息
  FaceUpdate( ClearOldFolderList );

    // 寻找共享目录
  FindNetworkFolderList;

    // 显示共享目录
  FaceUpdate( ShowNetworkFolderList );
end;

{ TLocalDriverRefresh }

constructor TLocalDriverRefresh.Create(_FolderPath: string);
begin
  FolderPath := _FolderPath;
  FileList := TFileList.Create;
end;

destructor TLocalDriverRefresh.Destroy;
begin
  FileList.Free;
  inherited;
end;

procedure TLocalDriverRefresh.FindDriverList;
var
  StrArray : TStringDynArray;
  i: Integer;
  FileInfo : TFileInfo;
begin
  StrArray := TDirectory.GetLogicalDrives;
  for i := 0 to Length( StrArray ) - 1 do
  begin
    if not MyFilePath.getDriverExist( StrArray[i] ) then
      Continue;
    FileInfo := TFileInfo.Create( StrArray[i], False );
    FileList.Add( FileInfo );
  end;
end;

procedure TLocalDriverRefresh.FindFileList;
var
  FolderExplorer : TFolderExplorer;
begin
  FolderExplorer := TFolderExplorer.Create( FolderPath );
  FolderExplorer.SetFileList( FileList );
  FolderExplorer.Update;
  FolderExplorer.Free;

  ReadHistoryList;
end;

procedure TLocalDriverRefresh.MoveFile(FileName: string);
var
  FilePos : Integer;
  i: Integer;
begin
  FilePos := -1;
  for i := 0 to FileList.Count - 1 do
  begin
    if FileList[i].IsFile and ( FilePos = -1 ) then // 第一个文件的位置
      FilePos := i;
    if FileList[i].FileName = FileName then  // 找到了路径
    begin
      if not FileList[i].IsFile then
        FileList.Move( i, 0 )
      else
      if FilePos >= 0 then
        FileList.Move( i, FilePos );
      Break;
    end;
  end;
end;

procedure TLocalDriverRefresh.ReadHistoryList;
var
  HistorySelectList : TStringList;
  IniFile : TIniFile;
  i: Integer;
begin
    // 读取历史选择
  HistorySelectList := TStringList.Create;
  IniFile := TIniFile.Create( MyAppData.getExplorerHistoryPath );
  try
    IniFile.ReadSection( FolderPath, HistorySelectList );
  except
  end;
  IniFile.Free;

    // 移动文件
  for i := 0 to HistorySelectList.Count - 1 do
    MoveFile( HistorySelectList[i] );
  HistorySelectList.Free;
end;

function TLocalDriverRefresh.ReadIsMyComputer: Boolean;
begin
  Result := FolderPath = '';
end;

procedure TLocalDriverRefresh.SetControlPath(_ControlPath: string);
begin
  ControlPath := _ControlPath;
end;

procedure TLocalDriverRefresh.ShowFileList;
var
  Params : TFileAddParams;
  i: Integer;
  ParentPath, UpPath : string;
begin
    // 控制页面
  if not FacePageDriverApi.ControlPage( ControlPath ) then
    Exit;

    // 清空旧信息
  FaceLocalDriverApi.Clear;

    // 返回父目录
  if FolderPath <> '' then
  begin
    UpPath := ExtractFileDir( FolderPath );
    if UpPath = FolderPath then
      UpPath := '';
    FaceLocalDriverApi.AddParentFolder( UpPath );
  end;

    // 添加
  ParentPath := MyFilePath.getPath( FolderPath );
  for i := 0 to FileList.Count - 1 do
  begin
    Params.FilePath := ParentPath + FileList[i].FileName;
    Params.IsFile := FileList[i].IsFile;
    Params.FileSize := FileList[i].FileSize;
    Params.FileTime := FileList[i].FileTime;
    if ReadIsMyComputer then
      FaceLocalDriverApi.AddDriver( Params )
    else
      FaceLocalDriverApi.Add( Params );
  end;
end;

procedure TLocalDriverRefresh.Update;
begin
    // 寻找文件列表
  if ReadIsMyComputer then
    FindDriverList
  else
    FindFileList;

    // 显示文件列表
  FaceUpdate( ShowFileList );
end;

{ TNetworkDriverRefresh }

constructor TNetworkDriverRefresh.Create(_FolderPath: string);
begin
  FolderPath := _FolderPath;
  FileList := TFileList.Create;
end;

destructor TNetworkDriverRefresh.Destroy;
begin
  FileList.Free;
  inherited;
end;

procedure TNetworkDriverRefresh.FindFileList;
var
  FolderExplorer : TFolderExplorer;
begin
  FolderExplorer := TFolderExplorer.Create( FolderPath );
  FolderExplorer.SetFileList( FileList );
  FolderExplorer.Update;
  FolderExplorer.Free;

  ReadHistoryList;
end;

procedure TNetworkDriverRefresh.MoveFile(FileName: string);
var
  FilePos : Integer;
  i: Integer;
begin
  FilePos := -1;
  for i := 0 to FileList.Count - 1 do
  begin
    if FileList[i].IsFile and ( FilePos = -1 ) then // 第一个文件的位置
      FilePos := i;
    if FileList[i].FileName = FileName then  // 找到了路径
    begin
      if not FileList[i].IsFile then
        FileList.Move( i, 0 )
      else
      if FilePos >= 0 then
        FileList.Move( i, FilePos );
      Break;
    end;
  end;
end;

procedure TNetworkDriverRefresh.ReadHistoryList;
var
  HistorySelectList : TStringList;
  IniFile : TIniFile;
  i: Integer;
begin
    // 读取历史选择
  HistorySelectList := TStringList.Create;
  IniFile := TIniFile.Create( MyAppData.getExplorerHistoryPath );
  try
    IniFile.ReadSection( FolderPath, HistorySelectList );
  except
  end;
  IniFile.Free;

    // 移动文件
  for i := 0 to HistorySelectList.Count - 1 do
    MoveFile( HistorySelectList[i] );
  HistorySelectList.Free;
end;

procedure TNetworkDriverRefresh.SetControlPath(_ControlPath: string);
begin
  ControlPath := _ControlPath;
end;

procedure TNetworkDriverRefresh.ShowFileList;
var
  Params : TFileAddParams;
  i: Integer;
  ParentPath : string;
begin
    // 控制页面
  if not FacePageDriverApi.ControlPage( ControlPath ) then
    Exit;

    // 清空旧信息
  FaceNetworkDriverApi.Clear;

      // 返回父目录
  if FolderPath <> ControlPath then
    FaceNetworkDriverApi.AddParentFolder( ExtractFileDir( FolderPath ) );

    // 添加
  ParentPath := MyFilePath.getPath( FolderPath );
  for i := 0 to FileList.Count - 1 do
  begin
    Params.FilePath := ParentPath + FileList[i].FileName;
    Params.IsFile := FileList[i].IsFile;
    Params.FileSize := FileList[i].FileSize;
    Params.FileTime := FileList[i].FileTime;
    FaceNetworkDriverApi.Add( Params );
  end;
end;

procedure TNetworkDriverRefresh.Update;
begin
    // 寻找文件列表
  FindFileList;

    // 显示文件列表
  FaceUpdate( ShowFileList );
end;

{ TFileListMarkSelectJob }

constructor TFileListMarkSelectJob.Create(_FolderPath, _SelectName: string);
begin
  FolderPath := _FolderPath;
  SelectName := _SelectName;
end;

procedure TFileListMarkSelectJob.Update;
var
  IniFile : TIniFile;
  HistoryList : TStringList;
begin
  IniFile := TIniFile.Create( MyAppData.getExplorerHistoryPath );
  try
      // 删除旧的位置
    IniFile.DeleteKey( FolderPath, SelectName );

      // 限制保存历史数
    HistoryList := TStringList.Create;
    IniFile.ReadSection( FolderPath, HistoryList );
    if HistoryList.Count >= 7 then
      IniFile.DeleteKey( FolderPath, HistoryList[0] );
    HistoryList.Free;

      // 添加到新的位置
    IniFile.WriteString( FolderPath, SelectName, SelectName );

      // 历史路径总数
    HistoryList := TStringList.Create;
    IniFile.ReadSections( HistoryList );
    try
      if HistoryList.Count > 100 then
        IniFile.EraseSection( HistoryList[0] );
    except
    end;
    HistoryList.Free
  except
  end;
  IniFile.Free;
end;

{ TFileListSelectJob }

constructor TFileListSelectJob.Create(_ControlPath, _FilePath: string);
begin
  ControlPath := _ControlPath;
  FilePath := _FilePath;
end;

procedure TFileListSelectJob.SelectPath;
begin
  if IsLocal then
    UserLocalDriverApi.Select( ControlPath, FilePath )
  else
    UserNetworkDriverApi.Select( ControlPath, FilePath );
end;

procedure TFileListSelectJob.SetIsLocal(_IsLocal: Boolean);
begin
  IsLocal := _IsLocal;
end;

procedure TFileListSelectJob.Update;
begin
  FaceUpdate( SelectPath );
end;

{ TFolderChangeNofityJob }

procedure TFolderChangeNofityJob.AddFile;
var
  FilePath : string;
begin
  FilePath := MyFilePath.getPath( FolderPath ) + FileName;
  if IsLocal then
    UserLocalDriverApi.AddFile( ControlPath, FilePath )
  else
    UserNetworkDriverApi.AddFile( ControlPath, FilePath );
end;

constructor TFolderChangeNofityJob.Create(_FolderPath: string);
begin
  FolderPath := _FolderPath;
  NewFileList := TStringList.Create;
  OldFileList := TStringList.Create;
end;

destructor TFolderChangeNofityJob.Destroy;
begin
  OldFileList.Free;
  NewFileList.Free;
  inherited;
end;

procedure TFolderChangeNofityJob.ReadNewFileList;
begin
  try
  if not DirectoryExists( FolderPath ) then
    Exit;
  TDirectory.GetFileSystemEntries( FolderPath,
    function(const Path: string; const SearchRec: TSearchRec): Boolean
    begin
      NewFileList.Add( SearchRec.Name );
      Result := False;
    end);
  except
  end;
end;

procedure TFolderChangeNofityJob.ReadOldFileList;
var
  PathList : TStringList;
  i: Integer;
begin
  if IsLocal then
    PathList := UserLocalDriverApi.ReadFileList( ControlPath )
  else
    PathList := UserNetworkDriverApi.ReadFileList( ControlPath );
  for i := 0 to PathList.Count - 1 do
    OldFileList.Add( ExtractFileName( PathList[i] ) );
  PathList.Free;
end;

procedure TFolderChangeNofityJob.RemoveFile;
var
  FilePath : string;
begin
  FilePath := MyFilePath.getPath( FolderPath ) + FileName;
  if IsLocal then
    UserLocalDriverApi.RemoveFile( ControlPath, FilePath )
  else
    UserNetworkDriverApi.RemoveFile( ControlPath, FilePath );
end;

procedure TFolderChangeNofityJob.SetControlPath(_ControlPath: string;
  _IsLocal: Boolean);
begin
  ControlPath := _ControlPath;
  IsLocal := _IsLocal;
end;

procedure TFolderChangeNofityJob.Update;
var
  i, FileIndex: Integer;
begin
    // 读取当前界面文件
  FaceUpdate( ReadOldFileList );

    // 读取当前硬盘文件
  ReadNewFileList;

    // 是否存在新增的文件
  for i := 0 to NewFileList.Count - 1 do
  begin
    FileName := NewFileList[i];
    FileIndex := OldFileList.IndexOf( FileName );
    if FileIndex >= 0 then
      OldFileList.Delete( FileIndex )
    else
      FaceUpdate( AddFile );
  end;

    // 是否存在已经删除的文件
  for i := 0 to OldFileList.Count - 1 do
  begin
    FileName := OldFileList[i];
    FaceUpdate( RemoveFile );
  end;
end;

end.
