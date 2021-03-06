unit hd_platform_designtime;

// platform dependent workout for the pgfdefs
// only the very necessary code
// one big source file

{$include pgf_config.inc}

interface

uses
  Classes, SysUtils,
  windows {$ifndef FPC},messages{$endif},
  hd_defs, Controls, graphics;

type
  TpgfWinHandle   = HWND;
  TpgfGContext    = HDC;

type
  TpgfWindowImpl = class;

  TpgfFontResourceImpl = class(TpgfFontResourceBase)
  private
    FFontData : HFONT;
    FMetrics : Windows.TEXTMETRIC;
  protected
    function OpenFontByDesc(const desc : string) : HFONT;

    property Handle : HFONT read FFontData;

  public
    constructor Create(const afontdesc : string);
    destructor Destroy; override;

    function HandleIsValid : boolean;

  public
    function GetAscent  : integer;
    function GetDescent : integer;
    function GetHeight  : integer;

    function GetTextWidth(const txt : widestring) : integer;
  end;

  TpgfFontImpl = class(TpgfFontBase)
  end;

  TpgfImageImpl = class(TpgfImageBase)
  private
    FBMPHandle : HBITMAP;
    FMaskHandle : HBITMAP;

    FIsTwoColor : boolean;             

    property BMPHandle : HBITMAP read FBMPHandle;
    property MaskHandle : HBITMAP read FMaskHandle;

  protected
    procedure DoFreeImage;

    procedure DoInitImage(acolordepth, awidth, aheight : integer; aimgdata : pointer);
    procedure DoInitImageMask(awidth, aheight : integer; aimgdata : pointer);

  public
    constructor Create;

  end;

  TpgfCanvasImpl = class(TpgfCanvasBase)
  private
    FDrawing : boolean;
    FBufferBitmap : HBitmap;
    FDrawWindow : TpgfWindowImpl;

    Fgc, FWinGC : TpgfGContext;
    FColorText : TpgfColor;
    FColor     : TpgfColor;
    FBackgroundColor : TpgfColor;
    FCurFontRes : TpgfFontResourceImpl;
    FClipRect  : TpgfRect;
    FClipRectSet : Boolean;
    FLineStyle : integer;
    FLineWidth : integer;

    FWindowsColor : longword;

    FBrush : HBRUSH;
    FPen   : HPEN;
    FClipRegion   : HRGN;

    FIntLineStyle, FIntLineWidth : integer;

  protected
    procedure DoSetFontRes(fntres : TpgfFontResourceImpl);
    procedure DoSetTextColor(cl : TpgfColor);
    procedure DoSetColor(cl : TpgfColor);
    procedure DoSetLineStyle(awidth: integer; astyle : TpgfLineStyle);

    procedure DoDrawString(x,y : TpgfCoord; const txt : widestring);

    procedure DoGetWinRect(var r : TpgfRect);

    procedure DoFillRectangle(x,y, w,h : TpgfCoord);
    procedure DoXORFillRectangle(col : TpgfColor; x, y, w, h : TpgfCoord);

    procedure DoFillTriangle(x1,y1, x2,y2, x3,y3 : TpgfCoord);

    procedure DoDrawRectangle(x,y, w,h : TpgfCoord);

    procedure DoDrawLine(x1,y1,x2,y2 : TpgfCoord);

    procedure DoDrawArc(x,y, w,h : TpgfCoord; a1, a2 : double);
    procedure DoFillArc(x,y, w,h : TpgfCoord; a1, a2 : double);

    procedure DoSetClipRect(const rect : TpgfRect);
    function DoGetClipRect : TpgfRect;
    procedure DoAddClipRect(const rect : TpgfRect);
    procedure DoClearClipRect;

    procedure DoDrawImagePart(x,y : TpgfCoord; img : TpgfImageImpl; xi,yi,w,h : integer);

    procedure DoBeginDraw(awin : TpgfWindowImpl; buffered : boolean);
    procedure DoPutBufferToScreen(x,y, w,h : TpgfCoord);
    procedure DoEndDraw;

  public
    constructor Create;
    destructor Destroy; override;
  end;

  TpgfWindowImpl = class(TWinControl)
  private
    function GetFLeft: integer;
    procedure SetFLeft(const Value: integer);
    function GetFTop: integer;
    procedure SetFTop(const Value: integer);
    function GetFWidth: integer;
    procedure SetFWidth(const Value: integer);
    function GetFHeight: integer;
    procedure SetFHeight(const Value: integer);
  protected
    FWindowType : TWindowType;
    FMinWidth: TpgfCoord;
    FMinHeight: TpgfCoord;
    FWindowAttributes : TWindowAttributes;
    
    FWinHandle : TpgfWinHandle;
    FModalForWin : TpgfWindowImpl;

    FWinStyle, FWinStyleEx : longword;
    FParentWinHandle : TpgfWinHandle;

    property WinHandle : TpgfWinHandle read FWinHandle;

    property FLeft : integer read GetFLeft write SetFLeft;
    property FTop : integer read GetFTop write SetFTop;
    property FWidth : integer read GetFWidth write SetFWidth;
    property FHeight : integer read GetFHeight write SetFHeight;
  protected
    procedure DoAllocateWindowHandle(aparent : TpgfWindowImpl);
    procedure DoReleaseWindowHandle;

    function HandleIsValid : boolean;

    procedure DoUpdateWindowPosition(aleft,atop,awidth,aheight : TpgfCoord);

    procedure DoMoveWindow(x,y : TpgfCoord);
    //procedure MoveToScreenCenter; override;

    procedure DoSetWindowTitle(const atitle : widestring);

  public
    property MinWidth  : TpgfCoord read FMinWidth write FMinWidth;
    property MinHeight : TpgfCoord read FMinHeight write FMinHeight;      
  
    constructor Create(aowner : TComponent); override;
    // make some setup before the window shows
    procedure AdjustWindowStyle; virtual;    // forms modify the window creation parameters
    procedure SetWindowParameters; virtual;  // invoked after the window is created    
  end;

  { TpgfDisplayImpl }

  TpgfDisplayImpl = class(TpgfDisplayBase)
  protected
    FDisplay : HDC;

    WindowClass : TWndClass;
    WidgetClass : TWndClass;

    hcr_default : HCURSOR;
    hcr_dir_ew  : HCURSOR;
    hcr_dir_ns  : HCURSOR;
    hcr_edit    : HCURSOR;

    hcr_dir_nwse,
    hcr_dir_nesw,
    hcr_move,
    hcr_crosshair : HCURSOR;

    FFocusedWindow : THANDLE;

    // double click generation
    LastClickWindow  : TpgfWinHandle;
    LastWinClickTime : longword;

    FInitialized : boolean;

    FTimerWnd : HWND;

  public
    constructor Create(const aparams : string); override;
    destructor Destroy; override;

  public
    function DoMessagesPending : boolean;
    procedure DoWaitWindowMessage(atimeoutms : integer);

    procedure DoFlush;

    function GetScreenWidth : TpgfCoord;
    function GetScreenHeight : TpgfCoord;

    procedure GetScreenCoordinates(atwindow : TpgfWindowImpl; x,y : TpgfCoord; out sx, sy : TpgfCoord);
    procedure GrabPointer(awin : TpgfWindowImpl);
    procedure UnGrabPointer;

    property PlatformInitialized : boolean read FInitialized;

  public
    property Display : HDC read FDisplay;
  end;

implementation

uses dialogs, hd_main, hd_widget, hd_form;

var
  wdisp : TpgfDisplay;

  MouseFocusedWH : HWND;

{$ifndef FPC}
type
  WndProc = TFNWndProc;
{$endif}

function pgfColorToWin(col : TpgfColor) : TpgfColor;
var
  c : dword;
begin
  c := pgfColorToRGB(col);

  //swapping bytes
  result := ((c and $FF0000) shr 16) or ((c and $0000FF) shl 16) or (c and $00FF00);
end;


function GetMyWidgetFromHandle(wh : TpgfWinHandle) : TpgfWidget;
begin
  if (wh <> 0) and (MainInstance = LongWord(GetWindowLong(wh, GWL_HINSTANCE))) then
  begin
    result := TpgfWidget(Windows.GetWindowLong(wh, GWL_USERDATA));
  end
  else result := nil;
end;

(*
procedure SendMouseMessage(wg : TWidget; msg : UINT; button : integer; wParam : WPARAM; lParam : LPARAM);
var
  p3 : integer;
  x,y : integer;
  wwg : TWidget;
  pwg : TWidget;
  h : THANDLE;
  pt : TPOINT;
begin
  x := SmallInt(lParam and $FFFF);
  y := SmallInt((lParam and $FFFF0000) shr 16);

  p3 := button shl 8;

  if (wParam and MK_CONTROL) <> 0 then p3 := p3 or ss_control;
  if (wParam and MK_SHIFT)   <> 0 then p3 := p3 or ss_shift;


  wwg := wg;

  if (PopupListFirst <> nil) then
  begin
    if wg = nil then Writeln('wg is NIL !!!');

    pt.x := x;
    pt.y := y;

    ClientToScreen(wg.WinHandle, pt);

    //Writeln('click x=',pt.X,' y=',pt.y);

    h := WindowFromPoint(pt);
    wwg := GetMyWidgetFromHandle(h);

    // if wwg <> nil then writeln('widget ok.');

    pwg := wwg;
    while (pwg <> nil) and (pwg.Parent <> nil) do pwg := pwg.Parent;

    if ((pwg = nil) or (PopupListFind(pwg.WinHandle) = nil)) and (not PopupDontCloseWidget(wwg)) and
       ((msg = MSG_MOUSEDOWN) or (msg = MSG_MOUSEUP)) then
    begin
      ClosePopups;

      SendMessage(nil, wwg, MSG_POPUPCLOSE, 0, 0, 0 );
    end;

    // sending the message...
    if wwg <> nil then
    begin
      ScreenToClient(wwg.WinHandle, pt);
      x := pt.x;
      y := pt.y;
    end;
  end;

  if ptkTopModalForm <> nil then
  begin
    pwg := WidgetParentForm(wwg);
    if (pwg <> nil) and (ptkTopModalForm <> pwg) then wwg := nil;
  end;

  if wwg <> nil then
  begin
    if (Msg = MSG_MOUSEDOWN) and (PopupListFirst = nil) then
    begin
      SetCapture(wwg.WinHandle);
    end
    else if (Msg = MSG_MOUSEUP) and (PopupListFirst = nil) then
    begin
      ReleaseCapture();
    end;

    SendMessage(nil, wwg, Msg, x, y, p3);

  end;

end;

*)


{ TpgfDisplayImpl }

constructor TpgfDisplayImpl.Create(const aparams: string);
begin
  // The lptk uses several writelines that we redirect to nul if {$APPTYPE GUI}

  FInitialized := false;

end;

destructor TpgfDisplayImpl.Destroy;
begin
  inherited Destroy;
end;

function TpgfDisplayImpl.DoMessagesPending: boolean;
var
  Msg: TMsg;
begin
  result := Windows.PeekMessageW( {$ifdef FPC}@{$endif} Msg, 0, 0, 0, PM_NOREMOVE);
end;

procedure TpgfDisplayImpl.DoWaitWindowMessage(atimeoutms : integer);
var
  Msg: TMsg;
  timerid  : longword;
  timerwnd : HWND;
  mp : boolean;
begin
  

end;

procedure TpgfDisplayImpl.DoFlush;
begin
  GdiFlush;
end;

function TpgfDisplayImpl.GetScreenWidth: TpgfCoord;
var
  r : TRECT;
begin
  GetWindowRect(GetDesktopWindow, r);

  result := r.Right - r.Left;
end;

function TpgfDisplayImpl.GetScreenHeight: TpgfCoord;
var
  r : TRECT;
begin
  GetWindowRect(GetDesktopWindow, r);

  result := r.Bottom - r.Top;
end;

procedure TpgfDisplayImpl.GetScreenCoordinates(atwindow : TpgfWindowImpl; x,y : TpgfCoord; out sx, sy : TpgfCoord);
var
  pt : TPoint;
begin
  pt.X := x;
  pt.Y := y;
  ClientToScreen(atwindow.WinHandle, pt);
  sx := pt.X;
  sy := pt.Y;
end;

procedure TpgfDisplayImpl.GrabPointer(awin : TpgfWindowImpl);
begin
  SetCapture(awin.WinHandle);
end;

procedure TpgfDisplayImpl.UnGrabPointer;
begin
  ReleaseCapture;
end;

{ TpgfWindowImpl }

procedure TpgfWindowImpl.DoAllocateWindowHandle(aparent : TpgfWindowImpl);

begin
end;

procedure TpgfWindowImpl.DoReleaseWindowHandle;
begin

end;

procedure TpgfWindowImpl.DoMoveWindow(x, y: TpgfCoord);
begin
end;

{
procedure TpgfWindowImpl.MoveToScreenCenter;
var
  r : TRECT;
begin
  GetWindowRect(WinHandle, r);
  FLeft := (wdisp.ScreenWidth-(r.Right - r.Left)) div 2;
  FTop := (wdisp.ScreenHeight-(r.Bottom - r.Top)) div 2;
  MoveWindow(FLeft,FTop);
end;
}

procedure TpgfWindowImpl.DoSetWindowTitle(const atitle: widestring);
var
  s8 : string;
begin
  Text := atitle; 
end;

constructor TpgfWindowImpl.Create(aowner: TComponent);
begin
  inherited;
  FWinHandle := 0;
end;

function TpgfWindowImpl.HandleIsValid: boolean;
begin
  result := FWinHandle > 0;
end;

procedure TpgfWindowImpl.DoUpdateWindowPosition(aleft, atop, awidth, aheight: TpgfCoord);
begin
  self.SetBounds(aleft, atop, awidth, aheight);
end;

procedure TpgfWindowImpl.AdjustWindowStyle;
begin

end;

procedure TpgfWindowImpl.SetWindowParameters;
begin

end;

function TpgfWindowImpl.GetFLeft: integer;
begin
  result := inherited left;
end;

procedure TpgfWindowImpl.SetFLeft(const Value: integer);
begin
  Left := value;
end;

function TpgfWindowImpl.GetFTop: integer;
begin
  result := inherited top;
end;

procedure TpgfWindowImpl.SetFTop(const Value: integer);
begin
  top := value;
end;

function TpgfWindowImpl.GetFWidth: integer;
begin
  result := width;
end;

procedure TpgfWindowImpl.SetFWidth(const Value: integer);
begin
  width := value;
end;

function TpgfWindowImpl.GetFHeight: integer;
begin
  result := height;
end;

procedure TpgfWindowImpl.SetFHeight(const Value: integer);
begin
  Height := value;
end;

{ TpgfCanvasImpl }

constructor TpgfCanvasImpl.Create;
begin
  FDrawing := false;
  FDrawWindow := nil;
  FBufferBitmap := 0;
end;

destructor TpgfCanvasImpl.Destroy;
begin
  if FDrawing then DoEndDraw;
  inherited;
end;

procedure TpgfCanvasImpl.DoBeginDraw(awin: TpgfWindowImpl; buffered : boolean);
var
  ARect : TpgfRect;
  bmsize : Windows.TSIZE;
begin
  if FDrawing and buffered and (FBufferBitmap > 0) then
  begin
    // check if the dimensions are ok
    GetBitmapDimensionEx(FBufferBitmap, bmsize);
    FDrawWindow := awin;
    DoGetWinRect(ARect);
    if (bmsize.cx <> ARect.width) or (bmsize.cy <> ARect.Height) then
    begin
      DoEndDraw;
    end;
  end;

  if not FDrawing then
  begin
    FDrawWindow := awin;

    FWinGC := windows.GetDC(FDrawWindow.FWinHandle);

    if buffered then
    begin
      DoGetWinRect(ARect);
      FBufferBitmap := windows.CreateCompatibleBitmap(FWinGC, ARect.Width, ARect.Height);
      Fgc := CreateCompatibleDC(FWinGC);
      SelectObject(Fgc, FBufferBitmap);
    end
    else
    begin
      FBufferBitmap := 0;
      Fgc := FWinGC;
    end;

    SetTextAlign(Fgc, TA_TOP); //TA_BASELINE);
    SetBkMode(Fgc, TRANSPARENT);
    
    FBrush := CreateSolidBrush(0);
    FPen := CreatePen(PS_SOLID, 0, 0);

    FClipRegion := CreateRectRgn(0,0,1,1);

    FColor := clText1;
    FLineStyle := PS_SOLID;
    FLineWidth := 0;
    FBackgroundColor := clBoxColor;
  end;
  
  FDrawing := true;
end;

procedure TpgfCanvasImpl.DoEndDraw;
begin
  if FDrawing then
  begin
    DeleteObject(FBrush);
    DeleteObject(FPen);
    DeleteObject(FClipRegion);

    if FBufferBitmap > 0 then DeleteObject(FBufferBitmap);
    FBufferBitmap := 0;

    if Fgc <> FWinGC then DeleteDC(Fgc);

    Windows.ReleaseDC(FDrawWindow.FWinHandle, FWingc);

    FDrawing := false;
    FDrawWindow := nil;
  end;
end;

procedure TpgfCanvasImpl.DoPutBufferToScreen(x, y, w, h: TpgfCoord);
begin
  if FBufferBitmap > 0 then BitBlt(FWinGC, x,y, w, h, Fgc, x, y, SRCCOPY);
end;

procedure TpgfCanvasImpl.DoAddClipRect(const rect: TpgfRect);
var
  rg : HRGN;
begin
  rg := CreateRectRgn(rect.left, rect.top, rect.left + rect.width, rect.top + rect.height);
  FClipRect := Rect;
  FClipRectSet := True;
  CombineRgn(FClipRegion,rg,FClipRegion,RGN_AND);
  SelectClipRgn(Fgc, FClipRegion);
  DeleteObject(rg);
end;

procedure TpgfCanvasImpl.DoClearClipRect;
begin
  SelectClipRgn(Fgc, 0);
  FClipRectSet := False;
end;

procedure TpgfCanvasImpl.DoDrawLine(x1, y1, x2, y2: TpgfCoord);
var
  pts : array[1..2] of windows.TPoint;
begin
  pts[1].X := x1; pts[1].Y := y1;
  pts[2].X := x2; pts[2].Y := y2;
  PolyLine(Fgc, pts, 2);
  SetPixel(Fgc, x2,y2, FWindowsColor);
end;

procedure TpgfCanvasImpl.DoDrawRectangle(x, y, w, h: TpgfCoord);
var
  wr : windows.TRect;
begin
  wr.Left := x;
  wr.Top  := y;
  wr.Right := x + w;
  wr.Bottom := y + h;
  Windows.FrameRect(Fgc, wr, FBrush);
end;

procedure TpgfCanvasImpl.DoDrawString(x, y: TpgfCoord; const txt: widestring);
begin
  if length(txt) < 1 then exit;

  windows.TextOutW(Fgc, x,y{+FCurFont.Ascent}, @txt[1], length(txt));
end;

procedure TpgfCanvasImpl.DoFillRectangle(x, y, w, h: TpgfCoord);
var
  wr : windows.TRect;
begin
  wr.Left := x;
  wr.Top  := y;
  wr.Right := x + w;
  wr.Bottom := y + h;
  Windows.FillRect(Fgc, wr, FBrush);
end;

procedure TpgfCanvasImpl.DoFillTriangle(x1, y1, x2, y2, x3, y3: TpgfCoord);
var
  pts : array[1..3] of windows.TPoint;
begin
  pts[1].X := x1; pts[1].Y := y1;
  pts[2].X := x2; pts[2].Y := y2;
  pts[3].X := x3; pts[3].Y := y3;
  Polygon(Fgc, pts, 3);
end;

function TpgfCanvasImpl.DoGetClipRect: TpgfRect;
begin
  result := FClipRect;
end;

procedure TpgfCanvasImpl.DoGetWinRect(var r: TpgfRect);
var
  wr : windows.TRECT;
begin
  GetClientRect(FDrawWindow.FWinHandle,wr);
  r.top := wr.Top;
  r.left := wr.Left;
  r.width := wr.Right - wr.Left + 1;
  r.height := wr.Bottom - wr.Top + 1;
end;

procedure TpgfCanvasImpl.DoSetClipRect(const rect: TpgfRect);
begin
  FClipRectSet := True;
  FClipRect := rect;
  DeleteObject(FClipRegion);
  FClipRegion := CreateRectRgn(rect.left, rect.top, rect.left + rect.width, rect.top + rect.height);
  SelectClipRgn(Fgc, FClipRegion);
end;

procedure TpgfCanvasImpl.DoSetColor(cl: TpgfColor);
begin
  DeleteObject(FBrush);
  DeleteObject(FPen);

  FWindowsColor := pgfColorToWin(cl);

  FBrush := CreateSolidBrush(FWindowsColor);
  FPen := CreatePen(FintLineStyle, FintLineWidth, FWindowsColor);
  SelectObject(Fgc,FBrush);
  SelectObject(Fgc,FPen);
end;

procedure TpgfCanvasImpl.DoSetLineStyle(awidth: integer; astyle: TpgfLineStyle);
begin
  if astyle = lsDashed then FintLineStyle := PS_DASH else FintLineStyle := PS_SOLID;
  FintLineWidth := awidth;
  DeleteObject(FPen);
  FPen := CreatePen(FintLineStyle, FintLineWidth, FWindowsColor);
  SelectObject(Fgc,FPen);
end;  

procedure TpgfCanvasImpl.DoSetTextColor(cl: TpgfColor);
begin
  Windows.SetTextColor(Fgc, pgfColorToWin(cl));
end;

procedure TpgfCanvasImpl.DoSetFontRes(fntres: TpgfFontResourceImpl);
begin
  if fntres = nil then Exit;
  FCurFontRes := fntres;
  Windows.SelectObject(Fgc, FCurFontRes.Handle);
end;

procedure TpgfCanvasImpl.DoDrawImagePart(x, y: TpgfCoord;
             img: TpgfImageImpl; xi, yi, w, h: integer);
const
  DSTCOPY = $00AA0029;
  ROP_DSPDxax = $00E20746;
var
  tmpdc : HDC;
  rop : longword;
begin
  if img = nil then exit;

  tmpdc := CreateCompatibleDC(wdisp.display);

  SelectObject(tmpdc, img.BMPHandle);

  if img.FIsTwoColor then rop := PATCOPY  //ROP_DSPDxax
                     else rop := SRCCOPY;

  if img.MaskHandle > 0 then
  begin
    MaskBlt(Fgc, x,y, w, h, tmpdc, xi, yi, img.MaskHandle, xi, yi, MakeRop4(rop, DSTCOPY));
  end
  else BitBlt(Fgc, x,y, w, h, tmpdc, xi, yi, rop);

  DeleteDC(tmpdc);
end;

procedure TpgfCanvasImpl.DoXORFillRectangle(col: TpgfColor; x, y, w, h: TpgfCoord);
var
  hb : HBRUSH;
  nullpen : HPEN;
begin
  hb := CreateSolidBrush(pgfColorToWin(pgfColorToRGB(col)));
  nullpen := CreatePen(PS_NULL,0,0);

  SetROP2(Fgc, R2_XORPEN);
  SelectObject(Fgc, hb);
  SelectObject(Fgc, nullpen);

  Windows.Rectangle(Fgc, x,y,x + w + 1,y + h + 1);

  SetROP2(Fgc, R2_COPYPEN);
  DeleteObject(hb);
  SelectObject(Fgc,FPen);
end;

procedure TpgfCanvasImpl.DoDrawArc(x, y, w, h: TpgfCoord; a1, a2: double);
var
  xr, yr : double;
begin
  xr := w / 2;
  yr := h / 2;
  Arc(Fgc, x,y,x+w,y+h,
    trunc(0.5 + x + xr + cos(a1)*xr),
    trunc(0.5 + y + yr - sin(a1)*yr),

    trunc(0.5 + x + xr + cos(a1+a2)*xr),
    trunc(0.5 + y + yr - sin(a1+a2)*yr)
  );
end;

procedure TpgfCanvasImpl.DoFillArc(x, y, w, h: TpgfCoord; a1, a2: double);
var
  xr, yr : double;
begin
  xr := w / 2;
  yr := h / 2;
  Pie(Fgc, x,y,x+w,y+h,
    trunc(0.5 + x + xr + cos(a1)*xr),
    trunc(0.5 + y + yr - sin(a1)*yr),

    trunc(0.5 + x + xr + cos(a1+a2)*xr),
    trunc(0.5 + y + yr - sin(a1+a2)*yr)
  );
end;

{ TpgfFontResourceImpl }

constructor TpgfFontResourceImpl.Create(const afontdesc : string);
begin
  FFontData := OpenFontByDesc(afontdesc);

  if HandleIsValid then
  begin
    SelectObject(wdisp.display, FFontData);
    GetTextMetrics(wdisp.display, FMetrics);
  end;
end;

destructor TpgfFontResourceImpl.Destroy;
begin
  if HandleIsValid then Windows.DeleteObject(FFontData);
  inherited;
end;

function TpgfFontResourceImpl.OpenFontByDesc(const desc: string): HFONT;
var
  lf : Windows.LOGFONT;

  facename : string;

  cp : integer;
  c : char;

  token : string;
  prop, propval : string;

  function NextC : char;
  begin
    inc(cp);
    if cp > length(desc) then c := #0
                         else c := desc[cp];
    result := c;
  end;

  procedure NextToken;
  begin
    token := '';
    while (c <> #0) and (c in [' ','a'..'z','A'..'Z','_','0'..'9']) do
    begin
      token := token + c;
      NextC;
    end;
  end;

begin
//  Writeln('ptkGetFont(''',desc,''')');

  FillChar(lf,sizeof(lf),0);

  with lf do
  begin
    lfWidth := 0; { have font mapper choose }
    lfEscapement := 0; { only straight fonts }
    lfOrientation := 0; { no rotation }
    lfWeight := FW_NORMAL;
    lfItalic := 0;
    lfUnderline := 0;
    lfStrikeOut := 0;
    lfCharSet := DEFAULT_CHARSET; //0; //Byte(Font.Charset);
    lfQuality := ANTIALIASED_QUALITY;
    { Everything else as default }
    lfOutPrecision := OUT_DEFAULT_PRECIS;
    lfClipPrecision := CLIP_DEFAULT_PRECIS;
    lfPitchAndFamily := DEFAULT_PITCH;
  end;

  cp := 0;
  NextC;

  NextToken;

//  Writeln('FaceName=',token);

  facename := token + #0;
  move(facename[1],lf.lfFaceName[0],length(facename));

  if c = '-' then
  begin
    NextC;
    NextToken;
    lf.lfHeight := -MulDiv(StrToIntDef(token,0), GetDeviceCaps(wdisp.display, LOGPIXELSY), 72);
  end;

  while c = ':' do
  begin
    NextC;
    NextToken;

    prop := UpperCase(token);
    propval := '';

    if c = '=' then
    begin
      NextC;
      NextToken;
      propval := UpperCase(token);
    end;

    if prop = 'BOLD' then
    begin
      lf.lfWeight := FW_BOLD;
      //Writeln('bold!');
    end
    else if prop = 'ITALIC' then
    begin
      lf.lfItalic := 1;
    end
    else if prop = 'ANTIALIAS' then
    begin
      if propval = 'FALSE' then lf.lfQuality := DEFAULT_QUALITY;
    end
    ;

  end;

  result := CreateFontIndirectA({$ifdef FPC}@{$endif}lf);
end;

function TpgfFontResourceImpl.HandleIsValid: boolean;
begin
  result := FFontData <> 0;
end;

function TpgfFontResourceImpl.GetAscent: integer;
begin
  result := FMetrics.tmAscent;
end;

function TpgfFontResourceImpl.GetDescent: integer;
begin
  result := FMetrics.tmDescent;
end;

function TpgfFontResourceImpl.GetHeight: integer;
begin
  result := FMetrics.tmHeight;
end;

function TpgfFontResourceImpl.GetTextWidth(const txt: widestring): integer;
var
  ts : Windows.SIZE;
begin
  if length(txt) < 1 then
  begin
    result := 0;
    exit;
  end;
  SelectObject(wdisp.display, FFontData);
  GetTextExtentPoint32W(wdisp.display, @txt[1], length(txt), ts);
  result := ts.cx;
end;

{ TpgfImageImpl }

constructor TpgfImageImpl.Create;
begin
  FBMPHandle := 0;
  FMaskHandle := 0;
  FIsTwoColor := false;
end;

procedure TpgfImageImpl.DoFreeImage;
begin
  if FBMPHandle > 0 then DeleteObject(FBMPHandle);
  FBMPHandle := 0;
  if FMaskHandle > 0 then DeleteObject(FMaskHandle);
  FMaskHandle := 0;
end;

procedure TpgfImageImpl.DoInitImage(acolordepth, awidth, aheight: integer; aimgdata: pointer);
var
  bi : TBitmapInfo;
begin
  if FBMPHandle > 0 then DeleteObject(FBMPHandle);

  FBMPHandle := CreateCompatibleBitmap(wdisp.display, awidth, aheight);

  FillChar(bi, sizeof(bi), 0);

  with bi.bmiHeader do
  begin
    biSize  := sizeof(bi);
    biWidth  := awidth;
    biHeight := -aheight;
    biPlanes := 1;
    if acolordepth = 1 then bibitcount := 1
                       else bibitcount := 32;
    biCompression := BI_RGB;
    biSizeImage := 0;
    biXPelsPerMeter := 96;
    biYPelsPerMeter := 96;
    biClrUsed := 0;
    biClrImportant := 0;
  end;

  SetDIBits(wdisp.display, FBMPHandle, 0, aheight, aimgdata, bi, DIB_RGB_COLORS);

  FIsTwoColor := (acolordepth = 1);
end;

type
  TMyMonoBitmap = packed record
    bmiHeader : TBitmapInfoHeader;
    bmColors : array[1..2] of longword;
  end;

procedure TpgfImageImpl.DoInitImageMask(awidth, aheight: integer; aimgdata: pointer);
var
  bi : TMyMonoBitmap;
  pbi : PBitmapInfo;
begin
  if FMaskHandle > 0 then DeleteObject(FMaskHandle);

  FMaskHandle := CreateBitmap(awidth, aheight, 1, 1, nil);

  FillChar(bi, sizeof(bi), 0);

  with bi.bmiHeader do
  begin
    biSize  := sizeof(bi.bmiHeader);
    biWidth  := awidth;
    biHeight := -aheight;
    biPlanes := 1;
    bibitcount := 1;
    biCompression := BI_RGB;
    biSizeImage := 0;
    biXPelsPerMeter := 96;
    biYPelsPerMeter := 96;
    biClrUsed := 2;
    biClrImportant := 0;
  end;
  bi.bmColors[1] := $000000;
  bi.bmColors[2] := $FFFFFF;

  pbi := @bi;
  SetDIBits(wdisp.display, FMaskHandle, 0, aheight, aimgdata, pbi^, DIB_RGB_COLORS);
end;

initialization
begin
  wdisp := nil;
  MouseFocusedWH := 0;
  showmessage('HDPLATFORM DESIGNTIME LOADED!');
end;

end.

