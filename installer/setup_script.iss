; ============================================
; Script de Inno Setup para CRES Carnets
; Sistema de Carnets de Salud - UAGro
; ============================================

#define MyAppName "CRES Carnets UAGro"
#define MyAppVersion "2.6.4"
#define MyAppPublisher "Universidad Autónoma de Guerrero"
#define MyAppURL "https://uagro.mx"
#define MyAppExeName "cres_carnets_ibmcloud.exe"
#define MyAppId "{{A7B8C9D0-E1F2-4A5B-9C8D-7E6F5A4B3C2D}"

[Setup]
; Información básica de la aplicación
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
LicenseFile=..\LICENSE.txt
InfoBeforeFile=..\installer\info_before.txt
OutputDir=..\releases\installers
OutputBaseFilename=CRES_Carnets_Setup_v{#MyAppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "Crear icono en el escritorio"; GroupDescription: "Iconos adicionales"
Name: "quicklaunchicon"; Description: "Crear icono de inicio rapido"; GroupDescription: "Iconos adicionales"

[Files]
; Copiar todo el contenido del build de Flutter
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; Archivo de versión
Source: "..\version.json"; DestDir: "{app}"; Flags: ignoreversion
; README y documentación
Source: "..\installer\README_USUARIO.txt"; DestDir: "{app}"; Flags: ignoreversion isreadme

[Icons]
; Icono en el menú inicio
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
; Icono en el escritorio
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
; Icono de inicio rápido
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunchicon

[Run]
; Ejecutar la aplicación después de instalar
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
// Verificar si hay una versión anterior instalada
function InitializeSetup(): Boolean;
var
  OldVersion: String;
  Uninstaller: String;
  ResultCode: Integer;
begin
  Result := True;
  
  // Verificar si existe instalación previa
  if RegQueryStringValue(HKEY_LOCAL_MACHINE, 
    'Software\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppId}_is1',
    'DisplayVersion', OldVersion) then
  begin
    if MsgBox('Se detectó una versión anterior (' + OldVersion + ') instalada.' + #13#10 + 
              '¿Desea desinstalarla antes de continuar?', 
              mbConfirmation, MB_YESNO) = IDYES then
    begin
      // Obtener la ruta del desinstalador
      RegQueryStringValue(HKEY_LOCAL_MACHINE,
        'Software\Microsoft\Windows\CurrentVersion\Uninstall\{#MyAppId}_is1',
        'UninstallString', Uninstaller);
      
      // Ejecutar desinstalador silencioso
      Exec(RemoveQuotes(Uninstaller), '/SILENT', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
      
      // Esperar un momento para que el desinstalador termine
      Sleep(2000);
    end;
  end;
end;

// Mensaje de bienvenida personalizado
function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  
  if CurPageID = wpWelcome then
  begin
    MsgBox('Bienvenido al instalador de CRES Carnets UAGro.' + #13#10 + #13#10 +
           'Este sistema permite la gestión digital de carnets de salud estudiantil.' + #13#10 + #13#10 +
           'Desarrollado por la Universidad Autónoma de Guerrero.',
           mbInformation, MB_OK);
  end;
end;

[UninstallDelete]
; Eliminar archivos de configuración y cache al desinstalar
Type: filesandordirs; Name: "{userappdata}\{#MyAppName}"
Type: filesandordirs; Name: "{localappdata}\{#MyAppName}"
