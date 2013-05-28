unit UMyUtils;

interface

uses classes, SysUtils, shlobj, Controls, shellapi, windows, Graphics, inifiles, IOUtils, StrUtils,
     Dialogs, DateUtils;

type

  MyFilePath = class
  public
    class function getIsRoot( Path : string ): Boolean;
    class function getPath( Path : string ) : string;
    class function getName( Path : string ) : string;
    class function getRenamePath( Path : string; IsFile : Boolean ): string;
    class function getIsExist( Path : string; IsFile : Boolean ): Boolean;
  public
    class function getDriverExist( Path : string ): Boolean;
    class function getDriverName( DriverPath : string ): string;
    class function getIsFixedDriver( DriverPath : string ): Boolean;
  public
    class function ReadIsConflict( SourceList : TStringList; DesFolder : string ): Boolean;
  end;

  MyFileInfo = class
  public
    class function getFileSize( Path : string ): Int64;
    class function getFileTime( Path : string ): TDateTime;
    class function getIsHide( Path : string ): Boolean;
  end;

  MySizeUtil = class
  public
    class function getFileSizeStr(FileSize: Int64): string;
  end;

  MyExplorer = class
  public
    class procedure RunFile( FilePath : string );
    class procedure ShowFolder( FolderPath : string );
    class procedure OpenRecycle;
  end;

  MyShellFile = class
  public
    class function DeleteFile( FilePath : string ): Boolean;
  end;

  MyInternetExplorer = class
  public
    class procedure OpenWeb( Url : string );
  end;

  MyThreadUtil = class
  public
    class procedure Run( ThreadProc: TProc );
    class procedure FaceRun( AMethod: TThreadProcedure );
  end;

  MyAppData = class
  public
    class function getPath : string;
    class function getIconFolderPath : string;
    class function getIconPicturePath : string;
    class function getLoginPath : string;
  public
    class function getConfigPath : string;
    class function getExplorerHistoryPath : string;
  public
    class function getNetworkDriver : string;
  end;

    // 保存 Icon 文件
  TSaveMyIconHandle = class
  public
    il : TImageList;
  public
    constructor Create( _il : TImageList );
    procedure Update;
  private
    function ReadIsIconEditionModify : Boolean;
    procedure ResetIconEdition;
  end;

      // 系统图标类
  TMyIcon = class
  private
    SysIcon: TImageList;
    SysIcon32 : TImageList;
  public
    constructor Create;
    destructor Destroy; override;
  public
    function getSysIcon: TImageList;
    function getSysIcon32 : TImageList;
  public
    function getPathIcon( Path : string ): Integer;overload;
    function getPathIcon( Path : string; IsFile : Boolean ): Integer;overload;
    function getFileIcon( FilePath : string ): Integer;
    function getFolderIcon( FolderPath : string ): Integer;
    function getFileExtIcon( FileName : string ): Integer;
  end;

      // 16 图标辅助类
  My16IconUtil = class
  public
    class function getFile : Integer;
    class function getFolder : Integer;
    class function getBack : Integer;
    class function getDelete : Integer;
    class function getZip : Integer;
    class function getLeft : Integer;
    class function getRight : Integer;
    class function getReplace : Integer;
    class function getRename : Integer;
    class function getCancel : Integer;
  public
    class function getIcon( IconIndex : Integer ): Integer;
    class function getIconPath( IconIndex : Integer ): string;
    class function getBasePath : string;
    class procedure Set16IconName( il :  TImageList );
  end;

  MyMessageForm = class
  public
    class procedure ShowWarnning( ShowStr : string );
    class procedure ShowError( ShowStr : string );
    class procedure ShowInformation( ShowStr : string );
    class function ShowConfirm( ShowStr : string ): Boolean;
  end;

const
  FileSize_B = ' B';
  FileSize_KB = ' KB';
  FileSize_MB = ' MB';
  FileSize_GB = ' GB';

  Size_B: Int64 = 1;
  Size_KB: Int64 = 1024;
  Size_MB: Int64 = 1024 * 1024;
  Size_GB: Int64 = 1024 * 1024 * 1024;

const
  IconEdition_Now = 1;

const
  LocalIcon_File = 0;
  LocalIcon_Folder = 1;
  LocalIcon_Favorite = 2;
  LocalIcon_AllFiles = 3;
  LocalIcon_Paste = 4;
  LocalIcon_Copy = 5;
  LocalIcon_Move = 6;
  LocalIcon_Delete = 7;
  LocalIcon_Zip = 8;
  LocalIcon_Replace = 9;
  LocalIcon_Rename = 10;
  LocalIcon_Cancel = 11;
  LocalIcon_Warnning = 12;
  LocalIcon_Back = 13;
  LocalIcon_Stop = 14;
  LocalIcon_Left = 15;
  LocalIcon_Right = 16;

var
  IconName_16 : string = '';
  IconName_32 : string = '';

var
  MyIcon : TMyIcon;

const
  MessageForm_Error = '错误';
  MessageForm_Information = '信息';
  MessageForm_Warnning = '警告';


implementation

{ MyThreadUtil }

class procedure MyThreadUtil.FaceRun(AMethod: TThreadProcedure);
begin
  try
    TThread.CurrentThread.Synchronize( TThread.CurrentThread, AMethod );
  except
  end;
end;

class procedure MyThreadUtil.Run(ThreadProc: TProc);
begin
  try
    TThread.CreateAnonymousThread( ThreadProc ).Start;
  except
  end;
end;

{ MyAppData }

class function MyAppData.getExplorerHistoryPath: string;
begin
  Result := getLoginPath + 'History.ini';
end;

class function MyAppData.getIconFolderPath: string;
begin
  Result := getPath + 'Icon\';
end;

class function MyAppData.getIconPicturePath: string;
begin
  Result := getIconFolderPath + 'Picture\';
end;

class function MyAppData.getPath: string;
var
  FilePath: array [0..255] of char;
begin
  try  // 从系统 Api 中获取
    SHGetSpecialFolderPath(0, @FilePath[0], CSIDL_COMMON_APPDATA, True);
    Result := FilePath;
    Result := Result + '\NetworkDriver\';
  except
  end;
end;

{ TMyIcon }

constructor TMyIcon.Create;
var
  SysIL, SysIL32 : THandle;
  SFI, SFI32 : TSHFileInfo;
begin
  try   // 16 * 16 系统图标 创建
    SysIcon := TImageList.Create(nil);
    SysIL := SHGetFileInfo('', 0, SFI, SizeOf(SFI), SHGFI_SYSICONINDEX or SHGFI_SMALLICON);
    if SysIL <> 0 then
    begin
      SysIcon.Handle := SysIL;
      SysIcon.ShareImages := TRUE;
    end;
  except
  end;

  try  // 32 * 32 系统图标 创建
    SysIcon32 := TImageList.Create( nil );
    SysIL32 := SHGetFileInfo('', 0, SFI32, SizeOf(SFI32), SHGFI_SYSICONINDEX or SHGFI_LARGEICON);
    if SysIL32 <> 0 then
    begin
      SysIcon32.Handle := SysIL32;
      SysIcon32.ShareImages := TRUE;
    end;
  except
  end;
end;

destructor TMyIcon.Destroy;
begin
  SysIcon32.Free;
  SysIcon.Free;
  inherited;
end;

function TMyIcon.getFileExtIcon(FileName: string): Integer;
var
  FileInfo: TSHFileInfo;
begin
  try
    FileInfo.iIcon := 0;
    SHGetFileInfo(pchar('*' + ExtractFileExt(FileName)), 0, FileInfo, SizeOf(TSHFileInfo),SHGFI_SYSICONINDEX or SHGFI_SMALLICON or SHGFI_USEFILEATTRIBUTES);
    DestroyIcon(FileInfo.hIcon);
    Result := FileInfo.iIcon;
  except
    Result := 0;
  end;

    // 获取失败
  if Result = 0 then
    Result := My16IconUtil.getFile;
end;

function TMyIcon.getFileIcon(FilePath: string): Integer;
var
  FileInfo : TSHFileInfo;
begin
    // 文件不存在，取后缀
  if not FileExists( FilePath ) then
  begin
    Result := getFileExtIcon( FilePath );
    Exit;
  end;

  try   // 系统 Api
    FileInfo.iIcon := 0;
    SHGetFileInfo(pchar(FilePath), 0, FileInfo, SizeOf(TSHFileInfo), SHGFI_SYSICONINDEX or SHGFI_SMALLICON);
    DestroyIcon(FileInfo.hIcon);
    Result := FileInfo.iIcon;
  except
    Result := 0
  end;

    // 获取失败
  if Result = 0 then
    Result := getFileExtIcon( FilePath )
end;

function TMyIcon.getFolderIcon(FolderPath: string): Integer;
var
  FileInfo : TSHFileInfo;
begin
    // 目录不存在
  if not DirectoryExists( FolderPath ) then
  begin
    Result := My16IconUtil.getFolder;
    Exit;
  end;

  try    // 系统 Api
    FileInfo.iIcon := 0;
    SHGetFileInfo(pchar(FolderPath), 0, FileInfo, SizeOf(TSHFileInfo), SHGFI_SYSICONINDEX or SHGFI_SMALLICON);
    DestroyIcon(FileInfo.hIcon);
    Result := FileInfo.iIcon;
  except
    Result := 0
  end;

    // 获取失败
  if Result = 0 then
    Result := My16IconUtil.getFolder;
end;

function TMyIcon.getPathIcon(Path: string): Integer;
begin
  Result := getPathIcon( Path, FileExists( Path ) );
end;

function TMyIcon.getPathIcon(Path: string; IsFile: Boolean): Integer;
begin
  if IsFile then
    Result := getFileIcon( Path )
  else
    Result := getFolderIcon( Path );
end;

function TMyIcon.getSysIcon: TImageList;
begin
  Result := SysIcon;
end;

function TMyIcon.getSysIcon32: TImageList;
begin
  Result := SysIcon32;
end;

class function My16IconUtil.getFile: Integer;
begin
  Result := getIcon( LocalIcon_File );
end;

class function My16IconUtil.getFolder: Integer;
begin
  Result := getIcon( LocalIcon_Folder );
end;

class function My16IconUtil.getIcon(IconIndex: Integer): Integer;
begin
  Result := MyIcon.getFileIcon( getIconPath( IconIndex ) );
end;

class function My16IconUtil.getIconPath(IconIndex: Integer): string;
begin
  Result := getBasePath + IntToStr(IconIndex) + '.ico';
end;

class function My16IconUtil.getLeft: Integer;
begin
  Result := getIcon( LocalIcon_Left );
end;

class function My16IconUtil.getRight: Integer;
begin
  Result := getIcon( LocalIcon_Right );
end;

class function My16IconUtil.getZip: Integer;
begin
  Result := getIcon( LocalIcon_Zip );
end;

class procedure My16IconUtil.Set16IconName(il: TImageList);
var
  SaveMyIconHandle : TSaveMyIconHandle;
begin
  SaveMyIconHandle := TSaveMyIconHandle.Create( il );
  SaveMyIconHandle.Update;
  SaveMyIconHandle.Free;

  IconName_16 := il.Name;
end;

class function My16IconUtil.getBack: Integer;
begin
  Result := getIcon( LocalIcon_Back );
end;

class function My16IconUtil.getBasePath: string;
begin
  Result := MyAppData.getIconFolderPath + IconName_16 + '\';
end;

class function My16IconUtil.getDelete: Integer;
begin
  Result := getIcon( LocalIcon_Delete );
end;

{ TSaveMyIconHandle }

constructor TSaveMyIconHandle.Create(_il: TImageList);
begin
  il := _il;
end;

function TSaveMyIconHandle.ReadIsIconEditionModify: Boolean;
var
  iniFile : TIniFile;
begin
  iniFile := TIniFile.Create( MyAppData.getConfigPath );
  try
    Result := iniFile.ReadInteger( 'Icon', 'Edition', 0 ) <> IconEdition_Now;
  except
  end;
  iniFile.Free;
end;

procedure TSaveMyIconHandle.ResetIconEdition;
var
  iniFile : TIniFile;
begin
  iniFile := TIniFile.Create( MyAppData.getConfigPath );
  try
    iniFile.WriteInteger( 'Icon', 'Edition', IconEdition_Now );
  except
  end;
  iniFile.Free;
end;

procedure TSaveMyIconHandle.Update;
var
  IsEditionModify : Boolean;
  i : Integer;
  Icon : TIcon;
  FolderPath, FilePath : string;
begin
    // 程序版本是否发生变化
  IsEditionModify := ReadIsIconEditionModify;

    // 创建图标目录
  FolderPath := MyAppData.getIconFolderPath + il.Name;
  ForceDirectories( FolderPath );

    // 保存文件
  FolderPath := MyFilePath.getPath( FolderPath );
  for i := 0 to il.Count - 1 do
  begin
    FilePath := FolderPath + IntToStr(i) + '.ico';

      // 是否需要重新保存文件
    if FileExists( FilePath ) and not IsEditionModify then
      Continue;

      // 提取图标并保存
    Icon := TIcon.Create;
    il.GetIcon( i, Icon );
    Icon.SaveToFile( FilePath );
    Icon.Free;
  end;

    // 设置已保存最新版本
  ResetIconEdition;
end;

class function MyAppData.getConfigPath: string;
begin
  Result := getLoginPath + 'Config.ini';
end;

class function MyAppData.getLoginPath: string;
var
  FStr: PChar;
  FSize: Cardinal;
begin
  try
    FSize := 255;
    GetMem(FStr, FSize);
    GetUserName(FStr, FSize);
    Result := FStr;
    FreeMem(FStr);
  except
    Result := 'Admin';
  end;

  Result := getPath + Result + '\';
end;

class function MyAppData.getNetworkDriver: string;
begin
  Result := getIconPicturePath + 'Driver.bmp';
end;

class function MyFilePath.getDriverExist(Path: string): Boolean;
var
  NotUsed, VolFlags: DWORD;
  Buf: array[0..MAX_PATH] of Char;
begin
  try
    Result := GetVolumeInformation(PChar(Path), Buf, sizeof(Buf), nil, NotUsed, VolFlags, nil, 0);
  except
    Result := False;
  end;
end;

class function MyFilePath.getDriverName(DriverPath: string): string;
var
  FI: TSHFileInfo;
begin
  try
    if SHGetFileInfo( PChar(DriverPath), 0, FI, SizeOf(FI), SHGFI_DISPLAYNAME ) = 0 then
      Result := DriverPath
    else
      Result := FI.szDisplayName;
  except
    Result := DriverPath;
  end;
end;

class function MyFilePath.getIsExist(Path: string; IsFile: Boolean): Boolean;
begin
  if IsFile then
    Result := FileExists( Path )
  else
    Result := DirectoryExists( Path );
end;

class function MyFilePath.getIsFixedDriver(DriverPath: string): Boolean;
begin
  try
    DriverPath := getPath( DriverPath );
    Result := GetDriveType(Pchar(DriverPath)) = DRIVE_FIXED;
  except
    Result := False;
  end;
end;

class function MyFilePath.getIsRoot(Path: string): Boolean;
begin
  Result := ExtractFileName( Path ) = '';
end;

class function MyFilePath.getPath(Path: string): string;
begin
  if Path = '' then
    Result := ''
  else
  if RightStr( Path, 1 ) <> '\' then
    Result := Path + '\'
  else
    Result := Path;
end;

class function MyFilePath.getRenamePath(Path: string; IsFile: Boolean): string;
var
  FileNum : Integer;
begin
  FileNum := 1;
  Result := Path;
  if IsFile then
  begin
    while True do
    begin
      if not FileExists( Result ) then
        Break;
      Result := ExtractFilePath( Path ) +  TPath.GetFileNameWithoutExtension( Path ) + '('+ IntToStr(FileNum) + ')' + ExtractFileExt( Path );
      Inc( FileNum );
    end;
  end
  else
  begin
    while True do
    begin
      if not DirectoryExists( Result ) then
        Break;
      Result := Path + '('+ IntToStr(FileNum) + ')';
      Inc( FileNum );
    end;
  end;
end;

class function MyFilePath.ReadIsConflict(SourceList: TStringList;
  DesFolder: string): Boolean;
var
  i : Integer;
  TargetFolder : string;
  SourcePath, TargetPath : string;
begin
  Result := False;
  TargetFolder := MyFilePath.getPath( DesFolder );
  for i := 0 to SourceList.Count - 1 do
  begin
    SourcePath := SourceList[i];
    TargetPath := TargetFolder + ExtractFileName( SourcePath );
    if FileExists( TargetPath ) or DirectoryExists( TargetPath ) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

class function MyFilePath.getName(Path: string): string;
begin
  Result := ExtractFileName( Path );
  if Result = '' then
    Result := Path;
end;


{ MySizeUtil }

class function MySizeUtil.getFileSizeStr(FileSize: Int64): string;
const
  FileSizeShowLen: Integer = 3;
var
  FileSizeDouble: Double;
  FileSizeExt: string;
  FileSizeLen: Integer;
  i: Integer;
  a: Integer;
begin
  if FileSize < 0 then
    FileSize := 0;

  if FileSize >= Size_GB then
  begin
    FileSizeDouble := FileSize / Size_GB;
    FileSizeExt := FileSize_GB;
  end
  else
    if FileSize >= Size_MB then
    begin
      FileSizeDouble := FileSize / Size_MB;
      FileSizeExt := FileSize_MB;
    end
    else
      if FileSize >= Size_KB then
      begin
        FileSizeDouble := FileSize / Size_KB;
        FileSizeExt := FileSize_KB;
      end
      else
      begin
        FileSizeDouble := FileSize;
        FileSizeExt := FileSize_B;
      end;

  FileSizeLen := Length(IntToStr(trunc(FileSizeDouble)));
  a := 1;
  for i := 0 to FileSizeShowLen - FileSizeLen - 1 do
    a := a * 10;
  FileSizeDouble := Trunc(FileSizeDouble * a) / a;

  Result := FloatToStr(FileSizeDouble) + FileSizeExt;
end;

class function MyFileInfo.getFileSize(Path: string): Int64;
var
  sch: TSearchRec;
begin
  Result := 0;
  try
    if FindFirst( Path , faAnyfile , sch ) = 0 then
      Result := sch.Size;
    SysUtils.FindClose(sch);
  except
  end;
end;

class function MyFileInfo.getFileTime(Path: string): TDateTime;
var
  sch: TSearchRec;
  LastWriteTimeSystem: TSystemTime;
begin
  Result := Now;
  try
    if FindFirst( Path, faAnyFile, sch ) = 0 then
    begin
      FileTimeToSystemTime( sch.FindData.ftLastWriteTime, LastWriteTimeSystem );
      Result := SystemTimeToDateTime(LastWriteTimeSystem);
      Result := TTimeZone.Local.ToLocalTime( Result );
    end;
    SysUtils.FindClose(sch);
  except
  end;
end;

class function MyFileInfo.getIsHide(Path: string): Boolean;
var
  sch: TSearchRec;
begin
  Result := True;
  try
    if FindFirst( Path , faAnyfile , sch ) = 0 then
      Result := ( sch.Attr and faHidden ) > 0;
    SysUtils.FindClose(sch);
  except
  end;
end;

{ MyExplorer }

class procedure MyExplorer.OpenRecycle;
begin
  ShellExecute(0, 'open', '::{645FF040-5081-101B-9F08-00AA002F954E}', nil, nil, SW_NORMAL);
end;

class procedure MyExplorer.RunFile(FilePath: string);
begin
  if FileExists( FilePath ) then
    ShellExecute( 0, 'open', Pchar( FilePath ), '', nil, SW_SHOW );
end;

class procedure MyExplorer.ShowFolder(FolderPath: string);
begin
  ShellExecute( 0, 'open', 'explorer.exe', PChar(FolderPath ), nil, SW_SHOW )
end;

{ MyMessageForm }

class function MyMessageForm.ShowConfirm(ShowStr: string): Boolean;
begin
  Result := MessageDlg( ShowStr, mtConfirmation, [mbYes, mbNo], 0 ) = mrYes;
end;

class procedure MyMessageForm.ShowError(ShowStr: string);
begin
  MessageBox( 0, PChar( ShowStr ), PChar( MessageForm_Error ), MB_ICONERROR );
end;

class procedure MyMessageForm.ShowInformation(ShowStr: string);
begin
  MessageBox( 0, PChar( ShowStr ), PChar( MessageForm_Information ), MB_ICONINFORMATION );
end;

class procedure MyMessageForm.ShowWarnning(ShowStr: string);
begin
  MessageBox( 0, PChar( ShowStr ), PChar( MessageForm_Warnning ), MB_ICONWARNING );
end;


{ MyShellFile }

class function MyShellFile.DeleteFile(FilePath: string): Boolean;
var
  fo: TSHFILEOPSTRUCT;
begin
  FillChar(fo, SizeOf(fo), 0);
  with fo do
  begin
    Wnd := 0;
    wFunc := FO_DELETE;
    pFrom := PChar(FilePath + #0);
    fFlags :=  FOF_ALLOWUNDO or FOF_NOCONFIRMATION;
  end;
  Result := SHFileOperation(fo) = 0;
end;

class function My16IconUtil.getRename: Integer;
begin
  Result := getIcon( LocalIcon_Rename );
end;

class function My16IconUtil.getReplace: Integer;
begin
  Result := getIcon( LocalIcon_Replace );
end;

class function My16IconUtil.getCancel: Integer;
begin
  Result := getIcon( LocalIcon_Cancel );
end;

{ MyInternetExplorer }

class procedure MyInternetExplorer.OpenWeb(Url: string);
begin
  try
    ShellExecute(0, 'open', pchar( Url ), '', '', SW_Show);
  except
  end;
end;

end.
