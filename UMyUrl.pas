unit UMyUrl;

interface

uses IdHttp, classes;

const
  Url_Home = 'http://purplewind.sinaapp.com/';
  Url_MarkApp = Url_Home + 'UserMark.php';
  Url_ReadDownload = Url_Home + 'ReadDownload.php';

type

  UrlUtil = class
  public
    class function ReadFileUrl( FileName : string ): string;
  end;


implementation

{ UrlUtil }

class function UrlUtil.ReadFileUrl(FileName: string): string;
var
  Http : TIdHTTP;
  ParamsList : TStringList;
  HttpResult, DownTag, DownEndTag, DownloadUrl : string;
  LengthDown : Integer;
begin
  Result := '';

    // 读取 Url
  Http := TIdHTTP.Create(nil);
  Http.ReadTimeout := 60000;
  Http.ConnectTimeout := 60000;
  ParamsList := TStringList.Create;
  ParamsList.Add( 'FileName=' + FileName );
  try
    HttpResult := Http.Post( Url_ReadDownload, ParamsList );
  except
    HttpResult := '';
  end;
  ParamsList.Free;
  Http.Free;

    // 访问网站失败
  if HttpResult = '' then
    Exit;

    // 提取下载地址
  try
    DownTag := '<Download-Url>';
    LengthDown := Length( DownTag );
    HttpResult := Copy( HttpResult, Pos( DownTag, HttpResult ) + LengthDown, length( HttpResult ) );
    DownEndTag := '</Download-Url>';
    HttpResult := Copy( HttpResult, 1, Pos( DownEndTag, HttpResult ) - 1 );
  except
  end;
  Result := HttpResult;
end;

end.
