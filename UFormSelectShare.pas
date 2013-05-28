unit UFormSelectShare;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  VirtualTrees, StrUtils, Vcl.ImgList;

type
  TfrmSelectShare = class(TForm)
    plButtons: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    vstShare: TVirtualStringTree;
    plTop: TPanel;
    Panel1: TPanel;
    plComputerList: TPanel;
    cbbComputer: TComboBox;
    Image1: TImage;
    procedure vstShareGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure vstShareGetImageIndex(Sender: TBaseVirtualTree;
      Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
      var Ghosted: Boolean; var ImageIndex: Integer);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure cbbComputerSelect(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure vstShareChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure vstShareDblClick(Sender: TObject);
  private
    InputPcList : TStringList;
    procedure SaveIni;
    procedure LoadIni;
  private
    procedure MainFormIni;
    procedure MainFormUnini;
  public
    function ReadInputList : TStringList;
    procedure AddInput( InputPc : string );
  public
    function NewShareFolder : Boolean;
    function ReadSharePath : string;
  end;

{$Region ' 界面 数据 ' }

    // 数据结构
  TVstShareData = record
  public
    SharePath : WideString;
  public
    ShowName : WideString;
    ShowIcon : Integer;
  end;
  PVstShareData = ^TVstShareData;

{$EndRegion}

{$Region ' 界面 操作 ' }

    // 计算机
  TFaceNetworkPcApi = class
  public
    cbbNetworkPc : TComboBox;
  public
    constructor Create;
  public
    procedure ClearComputer;
    procedure AddNewComputer;
    procedure AddComputer( ComputerName : string );
  public
    function ReadIsExist( ComputerName : string ): Boolean;
    procedure SelectPc( ComputerName : string );
  end;

    // 共享目录
  TFaceNetworkFolderApi = class
  public
    vstNetworkFolder : TVirtualStringTree;
  public
    constructor Create;
  public
    procedure Clear;
    procedure Add( NetworkFolder : string );
  end;

{$EndRegion}

{$Region ' 用户 操作 ' }

  UserNetworkPcApi = class
  public
    class procedure NewComputer;
    class procedure LoadComputer( ComputerName : string );
  end;

{$EndRegion}


{$Region ' 网上邻居 Api ' }

  TNetResourceArray = ^TNetResource;//网络类型的数组

  NetworkDriverUtil = class
  public
    class function ReadGroupList : TStringList;
    class function ReadGroupPcList( GroupName : string ): TStringList;
    class function ReadPcShareList( PcName : string ): TStringList;
  end;

{$EndRegion}

const
  Caption_NewComputer = '添加计算机...';
  Input_Caption = '添加计算机';
  Input_Name = '计算机名或者IP地址';

const
  Ini_SelectShare = 'SelectShare';
  Ini_ComputerName = 'ComputerName';
  Ini_ComputerCount = 'ComputerCount';

var
  FaceNetworkPcApi : TFaceNetworkPcApi;
  FaceNetworkFolderApi : TFaceNetworkFolderApi;

var
  frmSelectShare: TfrmSelectShare;


implementation

uses UMyUtils, IniFiles, UMyFaceThread;

{$R *.dfm}

{ TForm1 }


procedure TfrmSelectShare.AddInput(InputPc: string);
begin
    // 只保存 10 Pc
  if InputPcList.Count >= 10 then
    InputPcList.Delete( 0 );
  InputPcList.Add( InputPc );
end;

procedure TfrmSelectShare.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmSelectShare.cbbComputerSelect(Sender: TObject);
var
  ComputerName : string;
begin
  if cbbComputer.ItemIndex < 0 then
    Exit;

    // 读取计算机共享文件
  ComputerName := cbbComputer.Items[ cbbComputer.ItemIndex ];
  if ComputerName = Caption_NewComputer then
    UserNetworkPcApi.NewComputer
  else
    UserNetworkPcApi.LoadComputer( ComputerName );
end;

procedure TfrmSelectShare.FormCreate(Sender: TObject);
begin
  MainFormIni;
end;

procedure TfrmSelectShare.FormDestroy(Sender: TObject);
begin
  MainFormUnini;
end;

procedure TfrmSelectShare.FormShow(Sender: TObject);
begin
    // 刷新计算机
  MyFaceJobHandler.RefreshNetworkPc;
  vstShare.Clear;
end;

procedure TfrmSelectShare.LoadIni;
var
  IniFile : TIniFile;
  i, ComputerCount : Integer;
  ComputerName : string;
begin
  IniFile := TIniFile.Create( MyAppData.getConfigPath );
  try
    ComputerCount := IniFile.ReadInteger( Ini_SelectShare, Ini_ComputerCount, 0 );
    for i := 0 to ComputerCount - 1 do
    begin
      ComputerName := IniFile.ReadString( Ini_SelectShare, Ini_ComputerName + IntToStr( i ), '' );
      if ComputerName = '' then
        Continue;
      InputPcList.Add( ComputerName );
    end;
  except
  end;
  IniFile.Free;
end;

procedure TfrmSelectShare.MainFormIni;
begin
  FaceNetworkPcApi := TFaceNetworkPcApi.Create;
  FaceNetworkFolderApi := TFaceNetworkFolderApi.Create;

  InputPcList := TStringList.Create;
  LoadIni;
end;

procedure TfrmSelectShare.MainFormUnini;
begin
  SaveIni;
  InputPcList.Free;

  FaceNetworkFolderApi.Free;
  FaceNetworkPcApi.Free;
end;

function TfrmSelectShare.NewShareFolder: Boolean;
begin
  btnOK.Enabled := False;
  ModalResult := mrCancel;
  Result := ShowModal = mrOk;
end;

function TfrmSelectShare.ReadInputList: TStringList;
begin
  Result := InputPcList;
end;

function TfrmSelectShare.ReadSharePath: string;
var
  NodeData : PVstShareData;
begin
  Result := '';
  if not Assigned( vstShare.FocusedNode ) then
    Exit;
  NodeData := vstShare.GetNodeData( vstShare.FocusedNode );
  Result := NodeData.SharePath;
end;

procedure TfrmSelectShare.btnOKClick(Sender: TObject);
begin
  Close;
  ModalResult := mrOk;
end;

procedure TfrmSelectShare.SaveIni;
var
  IniFile : TIniFile;
  i : Integer;
begin
  IniFile := TIniFile.Create( MyAppData.getConfigPath );
  try
    IniFile.WriteInteger( Ini_SelectShare, Ini_ComputerCount, InputPcList.Count );
    for i := 0 to InputPcList.Count - 1 do
      IniFile.WriteString( Ini_SelectShare, Ini_ComputerName + IntToStr( i ), InputPcList[i] );
  except
  end;
  IniFile.Free;
end;

procedure TfrmSelectShare.vstShareChange(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
begin
  btnOK.Enabled := Sender.SelectedCount > 0;
end;

procedure TfrmSelectShare.vstShareDblClick(Sender: TObject);
begin
  if btnOK.Enabled then
    btnOK.Click;
end;

procedure TfrmSelectShare.vstShareGetImageIndex(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
  var Ghosted: Boolean; var ImageIndex: Integer);
var
  NodeData : PVstShareData;
begin
  ImageIndex := -1;
  if ( (Kind = ikNormal) or (Kind = ikSelected) ) and ( Column = 0 ) then
  begin
    NodeData := Sender.GetNodeData( Node );
    ImageIndex := NodeData.ShowIcon;
  end;
end;

procedure TfrmSelectShare.vstShareGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: string);
var
  NodeData : PVstShareData;
begin
  NodeData := Sender.GetNodeData( Node );
  if Column = 0 then
    CellText := NodeData.ShowName
  else
    CellText := '';
end;

{ NetworkDriverUtil }

class function NetworkDriverUtil.ReadGroupList: TStringList;
Var
  NetResource : TNetResource;
  Buf : Pointer;
  Count,BufSize,Res : DWORD;
  lphEnum : THandle;
  p : TNetResourceArray;
  i,j : SmallInt;
  NetworkTypeList : TList;
Begin
  Result := TStringList.Create;

  try
  NetworkTypeList := TList.Create;

    //获取整个网络中的文件资源的句柄，lphEnum为返回名柄
  Res := WNetOpenEnum( RESOURCE_GLOBALNET, RESOURCETYPE_DISK, RESOURCEUSAGE_CONTAINER, Nil,lphEnum);
  If Res <> NO_ERROR Then exit;//Raise Exception(Res);//执行失败

    //获取整个网络中的网络类型信息
  Count := $FFFFFFFF;//不限资源数目
  BufSize := 8192;//缓冲区大小设置为8K
  GetMem(Buf, BufSize);//申请内存，用于获取工作组信息
  Res := WNetEnumResource(lphEnum, Count, Pointer(Buf), BufSize);
  If ( Res = ERROR_NO_MORE_ITEMS )//资源列举完毕
  or (Res <> NO_ERROR )//执行失败
  Then
    Exit;
  P := TNetResourceArray(Buf);
  For I := 0 To Count - 1 Do//记录各个网络类型的信息
  Begin
    NetworkTypeList.Add(p);
    Inc(P);
  End;
  FreeMem( Buf );
  //WNetCloseEnum关闭一个列举句柄
  Res := WNetCloseEnum(lphEnum);//关闭一次列举
  If Res <> NO_ERROR Then exit;

  For J := 0 To NetworkTypeList.Count-1 Do //列出各个网络类型中的所有工作组名称
  Begin//列出一个网络类型中的所有工作组名称
    NetResource := TNetResource(NetworkTypeList.Items[J]^);//网络类型信息
    //获取某个网络类型的文件资源的句柄，NetResource为网络类型信息，lphEnum为返回名柄
    Res := WNetOpenEnum(RESOURCE_GLOBALNET, RESOURCETYPE_DISK,
    RESOURCEUSAGE_CONTAINER, @NetResource,lphEnum);
    If Res <> NO_ERROR Then break;//执行失败
    While true Do//列举一个网络类型的所有工作组的信息
    Begin
      Count := $FFFFFFFF;//不限资源数目
      BufSize := 8192;//缓冲区大小设置为8K
      GetMem(Buf, BufSize);//申请内存，用于获取工作组信息
      //获取一个网络类型的文件资源信息，
      Res := WNetEnumResource(lphEnum, Count, Pointer(Buf), BufSize);
      If ( Res = ERROR_NO_MORE_ITEMS ) //资源列举完毕
      or (Res <> NO_ERROR) //执行失败
      then
        break;
      P := TNetResourceArray(Buf);
      For I := 0 To Count - 1 Do//列举各个工作组的信息
      Begin
        Result.Add( StrPAS( P^.lpRemoteName ));//取得一个工作组的名称
        Inc(P);
      End;
      FreeMem( Buf );
    End;
    Res := WNetCloseEnum(lphEnum);//关闭一次列举
  End;
  NetworkTypeList.Free;
  except
  end;
End;

class function NetworkDriverUtil.ReadGroupPcList(
  GroupName: string): TStringList;
var
  GroupR: TNetResource;
  NetHand:THandle;
  BuffSize,Count:DWord;
  Buffer:Pointer;
  i:integer;
  RB:TNetResourceArray;
  bs:string;
begin
  Result := TStringList.Create;

  try
  FillChar(GroupR,sizeof(TNetResource),0);
  GroupR.dwScope := RESOURCE_GLOBALNET;
  GroupR.dwType := RESOURCETYPE_DISK	;
  GroupR.lpremoteName := Pchar(GroupName);
  GroupR.dwDisplayType := RESOURCEDISPLAYTYPE_server;
  GroupR.dwUsage := RESOURCEUSAGE_CONNECTABLE;
  if WNetOpenEnum(RESOURCE_GLOBALNET,RESOURCETYPE_DISK,0,@GroupR,NetHand)<>NO_ERROR then
    Exit;
  buffsize := sizeof(TNETRESOURCE)*1024;
  Count := $FFFFFFFF;
  GetMem(buffer,buffsize);
  if  WNetEnumResource(NetHand,Count,buffer,buffsize)= NO_ERROR	then
  begin
    RB := TNetResourceArray(buffer);
    For i := 0 to Count-1 do
    begin
      bs:=copy(RB^.lpRemoteName,0,strlen(RB^.lpRemoteName));
      Result.Add(bs);
      Inc(RB);
    end;
  end;
  WNetCloseEnum(NetHand);
  FreeMem(buffer);
  except
  end;
end;

class function NetworkDriverUtil.ReadPcShareList(PcName: string): TStringList;
var
NetResource : TNetResource;

  Buf : Pointer;

  Count,BufSize,Res : DWord;

  Ind : Integer;

  lphEnum : THandle;

  Temp : TNetResourceArray;
Begin
  Result := TStringList.Create;

  FillChar(NetResource, SizeOf(NetResource), 0);//初始化网络层次信息

  NetResource.lpRemoteName := @PcName[1];//指定计算机名称

  //获取指定计算机的网络资源句柄

  Res := WNetOpenEnum( RESOURCE_GLOBALNET, RESOURCETYPE_ANY,

  RESOURCEUSAGE_CONNECTABLE, @NetResource,lphEnum);

  If Res <> NO_ERROR Then exit;//执行失败

  While True Do//列举指定工作组的网络资源

  Begin

  Count := $FFFFFFFF;//不限资源数目

  BufSize := 8 * 1024;//缓冲区大小设置为8K

  GetMem(Buf, BufSize);//申请内存，用于获取工作组信息

  //获取指定计算机的网络资源名称

  Res := WNetEnumResource(lphEnum, Count, Pointer(Buf), BufSize);

  If Res = ERROR_NO_MORE_ITEMS Then break;//资源列举完毕

  If (Res <> NO_ERROR) then Exit;//执行失败

  Temp := TNetResourceArray(Buf);

  For Ind := 0 to Count - 1 do

  Begin

  //获取指定计算机中的共享资源名称，+2表示删除"＼"，

  //如＼wangfajun=>wangfajun

  Result.Add(Temp^.lpRemoteName + 2);

  Inc(Temp);

  End;

  End;

  Res := WNetCloseEnum(lphEnum);//关闭一次列举

  If Res <> NO_ERROR Then exit;//执行失败

  FreeMem(Buf);
End;

{ TFaceNetworkPcApi }

procedure TFaceNetworkPcApi.AddComputer(ComputerName: string);
begin
    // 网上邻居路径修正
  if LeftStr( ComputerName, 2 ) = '\\' then
    ComputerName := Copy( ComputerName, 3, length( ComputerName ) - 2 );

  if cbbNetworkPc.Items.IndexOf( ComputerName ) < 0 then
    cbbNetworkPc.Items.Insert( cbbNetworkPc.Items.Count - 1, ComputerName );
end;

procedure TFaceNetworkPcApi.AddNewComputer;
begin
  cbbNetworkPc.Items.Add( Caption_NewComputer );
end;

procedure TFaceNetworkPcApi.ClearComputer;
begin
  cbbNetworkPc.Clear;
end;

constructor TFaceNetworkPcApi.Create;
begin
  cbbNetworkPc := frmSelectShare.cbbComputer;
end;

function TFaceNetworkPcApi.ReadIsExist(ComputerName: string): Boolean;
begin
  Result := cbbNetworkPc.Items.IndexOf( ComputerName ) >= 0;
end;

procedure TFaceNetworkPcApi.SelectPc(ComputerName: string);
begin
  cbbNetworkPc.ItemIndex := cbbNetworkPc.Items.IndexOf( ComputerName );
end;

{ TFaceNetworkFolderApi }

procedure TFaceNetworkFolderApi.Add(NetworkFolder: string);
var
  ShareNode : PVirtualNode;
  ShareData : PVstShareData;
begin
    // 网上邻居路径修正
  if LeftStr( NetworkFolder, 2 ) <> '\\' then
    NetworkFolder := '\\' + NetworkFolder;

    // 添加界面
  ShareNode := vstNetworkFolder.AddChild( vstNetworkFolder.RootNode );
  ShareData := vstNetworkFolder.GetNodeData( ShareNode );
  ShareData.SharePath := NetworkFolder;
  ShareData.ShowName := ExtractFileName( NetworkFolder );
  ShareData.ShowIcon := MyIcon.getFolderIcon( NetworkFolder );
end;

procedure TFaceNetworkFolderApi.Clear;
begin
  vstNetworkFolder.Clear;
end;

constructor TFaceNetworkFolderApi.Create;
begin
  vstNetworkFolder := frmSelectShare.vstShare;
  vstNetworkFolder.NodeDataSize := SizeOf( TVstShareData );
  vstNetworkFolder.Images := MyIcon.getSysIcon;
end;

{ UserNetworkPcApi }

class procedure UserNetworkPcApi.LoadComputer(ComputerName: string);
begin
  MyFaceJobHandler.RefreshNetworkFolder( ComputerName );
end;

class procedure UserNetworkPcApi.NewComputer;
var
  ComputerName : string;
begin
    // 清空目录
  FaceNetworkFolderApi.Clear;

    // 输入计算机名或Ip
  ComputerName := '';
  if not InputQuery( Input_Caption, Input_Name, ComputerName ) or ( ComputerName = '' ) then
    Exit;

    // 已存在
  if FaceNetworkPcApi.ReadIsExist( ComputerName ) then
    Exit;

    // 添加计算机
  FaceNetworkPcApi.AddComputer( ComputerName );

    // 选中计算机
  FaceNetworkPcApi.SelectPc( ComputerName );

    // 加载文件列表
  LoadComputer( ComputerName );

    // 添加到保存Pc
  frmSelectShare.AddInput( ComputerName );
end;

end.
