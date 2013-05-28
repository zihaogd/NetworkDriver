unit UThreadUtil;

interface

uses Generics.Collections, classes, SyncObjs;

type

  THandleJobThread = class;

    // Job 信息
  TThreadJob = class
  private
    HandleJobThread : THandleJobThread;
  public
    procedure Update;virtual;abstract;
  protected
    procedure FaceUpdate( AMethod: TThreadMethod );
  private
    procedure SetHandleJobThread( _HandleJobThread : THandleJobThread );
  end;
  TThreadJobList = class( TObjectList<TThreadJob> )end;

    // 处理 Job 线程
  THandleJobThread = class( TThread )
  private
    JobLock : TCriticalSection;
    JobList : TThreadJobList;
  public
    constructor Create;
    destructor Destroy; override;
  protected
    procedure Execute; override;
  private
    procedure AddJob( ThreadJob : TThreadJob );
    function getJob: TThreadJob;
  end;

    // 控制器
  TMyJobHandler = class
  private
    IsRun : Boolean;
    HandleJobThread : THandleJobThread;
  public
    constructor Create;
    procedure Stop;
  protected
    procedure AddJob( ThreadJob : TThreadJob );
  end;

implementation

{ THandleThread }

procedure THandleJobThread.AddJob(ThreadJob: TThreadJob);
begin
  JobLock.Enter;
  JobList.Add( ThreadJob );
  JobLock.Leave;

  Resume;
end;

constructor THandleJobThread.Create;
begin
  inherited Create( True );
  JobLock := TCriticalSection.Create;
  JobList := TThreadJobList.Create;
  JobList.OwnsObjects := False;
end;

destructor THandleJobThread.Destroy;
begin
  Terminate;
  Resume;
  WaitFor;
  JobList.OwnsObjects := True;
  JobList.Free;
  JobLock.Free;
  inherited;
end;

procedure THandleJobThread.Execute;
var
  ThreadJob : TThreadJob;
begin
  while not Terminated do
  begin
    ThreadJob := getJob;
    if not Assigned( ThreadJob ) then
    begin
      if not Terminated then
        Suspend;
      Continue;
    end;
    ThreadJob.SetHandleJobThread( Self );
    try
      ThreadJob.Update;
    except
    end;
    ThreadJob.Free;
  end;
end;

function THandleJobThread.getJob: TThreadJob;
begin
  JobLock.Enter;
  if JobList.Count > 0 then
  begin
    Result := JobList[0];
    JobList.Delete(0);
  end
  else
    Result := nil;
  JobLock.Leave;
end;

{ TMyJobHandler }

procedure TMyJobHandler.AddJob(ThreadJob: TThreadJob);
begin
  if not IsRun then
    Exit;
  HandleJobThread.AddJob( ThreadJob );
end;

constructor TMyJobHandler.Create;
begin
  HandleJobThread := THandleJobThread.Create;
  IsRun := True;
end;

procedure TMyJobHandler.Stop;
begin
  IsRun := False;
  HandleJobThread.Free;
end;

{ TThreadJob }

procedure TThreadJob.FaceUpdate(AMethod: TThreadMethod);
begin
  HandleJobThread.Synchronize( AMethod );
end;

procedure TThreadJob.SetHandleJobThread(_HandleJobThread: THandleJobThread);
begin
  HandleJobThread := _HandleJobThread;
end;

end.
