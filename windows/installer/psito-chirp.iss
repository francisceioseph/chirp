; O instalador do Psito Chirp no Windows, gerado no CI com o Inno Setup.
;
;   ISCC /DAppVersion=1.2.3 windows\installer\psito-chirp.iss
;
; Por padrão instala só para quem está usando, sem pedir administrador; aí o Windows
; pergunta sobre a rede na primeira vez que o Chirp escuta. Quem instala para todos (no
; diálogo) ganha a regra do firewall para a rede local, que a desinstalação tira.
; As conversas ficam no perfil (o banco cifrado e a chave no Credential Manager), e
; desinstalar não apaga: para isso há o "Apagar tudo" no app.
#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#define AppName "Psito Chirp"
#define AppExe "psito_chirp.exe"
#define AppModelId "Psito.Chirp"
#define AppId "org.psito.chirp"
#define Release "..\..\build\windows\x64\runner\Release"

[Setup]
AppId={{5755B091-9D75-4CEB-A4B0-F42F2578395B}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=Psito Chirp contributors
AppPublisherURL=https://francisceioseph.github.io/chirp/
AppSupportURL=https://github.com/francisceioseph/chirp/issues
AppUpdatesURL=https://github.com/francisceioseph/chirp/releases
VersionInfoVersion={#AppVersion}
DefaultDirName={autopf}\{#AppName}
DisableProgramGroupPage=yes
DisableDirPage=auto
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
OutputDir=Output
OutputBaseFilename=psito-chirp-windows-x64-setup
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
CloseApplications=force
RestartApplications=no

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "pt"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "es"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "fr"; MessagesFile: "compiler:Languages\French.isl"
Name: "de"; MessagesFile: "compiler:Languages\German.isl"
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#Release}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\..\LICENSE"; DestDir: "{app}\licenses"; DestName: "LICENSE.txt"; Flags: ignoreversion
Source: "..\..\SECURITY.md"; DestDir: "{app}\licenses"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExe}"; AppUserModelID: "{#AppModelId}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; AppUserModelID: "{#AppModelId}"; Tasks: desktopicon

[Run]
; A rede local (o QUIC e o mDNS), nas redes privadas e de domínio. Só com administrador.
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall add rule name=""{#AppName}"" dir=in action=allow program=""{app}\{#AppExe}"" enable=yes profile=private,domain"; Flags: runhidden; Check: IsAdminInstallMode
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

; O Chirp pode estar na bandeja, segurando os arquivos
[UninstallRun]
Filename: "{sys}\taskkill.exe"; Parameters: "/f /im {#AppExe}"; Flags: runhidden; RunOnceId: "StopChirp"
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall delete rule name=""{#AppName}"" program=""{app}\{#AppExe}"""; Flags: runhidden; RunOnceId: "FirewallRule"; Check: IsAdminInstallMode

[UninstallDelete]
Type: dirifempty; Name: "{app}"

[Code]
// O "Abrir ao entrar no computador" do app fica no Run de quem usa (o id do app é o
// nome do valor). Sem o programa, a entrada sobraria apontando para o nada.
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
  begin
    RegDeleteValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Run', '{#AppId}');
    RegDeleteValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run', '{#AppId}');
  end;
end;
