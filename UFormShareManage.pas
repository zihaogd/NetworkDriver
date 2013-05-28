unit UFormShareManage;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, VirtualTrees, Vcl.StdCtrls;

type
  TfrmShareManger = class(TForm)
    vstHistory: TVirtualStringTree;
    plButtons: TPanel;
    btnOK: TButton;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
    procedure vstHistoryGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure vstHistoryGetImageIndex(Sender: TBaseVirtualTree;
      Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
      var Ghosted: Boolean; var ImageIndex: Integer);
    procedure FormShow(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure vstHistoryPaintText(Sender: TBaseVirtualTree;
      const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      TextType: TVSTTextType);
    procedure vstHistoryChecked(Sender: TBaseVirtualTree; Node: PVirtualNode);
  private
    { Private declarations }
  public
    procedure ClearFolders;
    procedure AddFolder( Path : string );
    procedure AddSelectAll;
    function ReadDelete : Boolean;
    function ReadPathList : TStringList;
  end;

  TVstHistoryManData = record
  public
    FolderPath : WideString;
  public
    FolderName, FolderDir : WideString;
    FolderIcon : Integer;
  public
    IsSelectAll : Boolean;
  end;
  PVstHistoryManData = ^TVstHistoryManData;

var
  HistoryShow_SelectAll : string = '全选';

var
  frmShareManger: TfrmShareManger;

implementation

uses UMyUtils;

{$R *.dfm}


procedure TfrmShareManger.AddFolder(Path: string);
var
  FolderNode : PVirtualNode;
  NodeData : PVstHistoryManData;
begin
  FolderNode := vstHistory.AddChild( vstHistory.RootNode );
  vstHistory.CheckType[ FolderNode ] := ctTriStateCheckBox;
  vstHistory.CheckState[ FolderNode ] := csUncheckedNormal;
  NodeData := vstHistory.GetNodeData( FolderNode );
  NodeData.FolderPath := Path;
  NodeData.FolderName := ExtractFileName( Path );
  NodeData.FolderDir := ExtractFileDir( Path );
  NodeData.FolderIcon := MyIcon.getFolderIcon( Path );
  NodeData.IsSelectAll := False;
end;

procedure TfrmShareManger.AddSelectAll;
var
  FolderNode : PVirtualNode;
  NodeData : PVstHistoryManData;
begin
  FolderNode := vstHistory.InsertNode( vstHistory.RootNode, amAddChildFirst );
  vstHistory.CheckType[ FolderNode ] := ctTriStateCheckBox;
  vstHistory.CheckState[ FolderNode ] := csUncheckedNormal;
  vstHistory.NodeHeight[ FolderNode ] := 23;
  NodeData := vstHistory.GetNodeData( FolderNode );
  NodeData.FolderName := HistoryShow_SelectAll;
  NodeData.FolderDir := '';
  NodeData.FolderIcon := -1;
  NodeData.IsSelectAll := True;
end;

procedure TfrmShareManger.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmShareManger.btnOKClick(Sender: TObject);
begin
  Close;
  ModalResult := mrOk;
end;

procedure TfrmShareManger.ClearFolders;
begin
  vstHistory.Clear;
end;

procedure TfrmShareManger.FormCreate(Sender: TObject);
begin
  vstHistory.NodeDataSize := SizeOf( TVstHistoryManData );
  vstHistory.Images := MyIcon.getSysIcon;
end;

procedure TfrmShareManger.FormShow(Sender: TObject);
begin
  ModalResult := mrCancel;
  btnOK.Enabled := False;
end;

function TfrmShareManger.ReadDelete: Boolean;
begin
  Result := ShowModal = mrOk;
end;

function TfrmShareManger.ReadPathList: TStringList;
var
  SelectNode : PVirtualNode;
  NodeData : PVstHistoryManData;
begin
  Result := TStringList.Create;
  SelectNode := vstHistory.GetFirstChecked;
  while Assigned( SelectNode ) do
  begin
    NodeData := vstHistory.GetNodeData( SelectNode );
    if not NodeData.IsSelectAll then
      Result.Add( NodeData.FolderPath );
    SelectNode := vstHistory.GetNextChecked( SelectNode );
  end;
end;

procedure TfrmShareManger.vstHistoryChecked(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
var
  NodeData : PVstHistoryManData;
  SelectNode : PVirtualNode;
  cs : TCheckState;
begin
  btnOK.Enabled := Sender.CheckedCount > 0;
  
  NodeData := Sender.GetNodeData( Node );
  if not NodeData.IsSelectAll then
    Exit;
  cs := Sender.CheckState[ Node ];
  SelectNode := Sender.RootNode.FirstChild;
  while Assigned( SelectNode ) do
  begin
    Sender.CheckState[ SelectNode ] := cs;
    SelectNode := SelectNode.NextSibling;
  end;
end;

procedure TfrmShareManger.vstHistoryGetImageIndex(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
  var Ghosted: Boolean; var ImageIndex: Integer);
var
  NodeData : PVstHistoryManData;
begin
  if ( (Kind = ikNormal) or (Kind = ikSelected) ) and ( Column = 0 ) then
  begin
    NodeData := Sender.GetNodeData( Node );
    ImageIndex := NodeData.FolderIcon;
  end
  else
    ImageIndex := -1;
end;

procedure TfrmShareManger.vstHistoryGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: string);
var
  NodeData : PVstHistoryManData;
begin
  NodeData := Sender.GetNodeData( Node );
  if Column = 0 then
    CellText := NodeData.FolderName
  else
  if Column = 1 then
    CellText := NodeData.FolderDir;
end;

procedure TfrmShareManger.vstHistoryPaintText(Sender: TBaseVirtualTree;
  const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  TextType: TVSTTextType);
var
  NodeData : PVstHistoryManData;
begin
  NodeData := Sender.GetNodeData( Node );
  if NodeData.IsSelectAll then
    TargetCanvas.Font.Style := TargetCanvas.Font.Style + [fsBold];
end;

end.
