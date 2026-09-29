#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$Repositorio = "https://github.com/uesb-academicos/PW2.git",
    [string]$Branch = "main"
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Stop-Publicacao([string]$Motivo) { throw $Motivo }
function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments=$true)][string[]]$GitArgs)
    & git @GitArgs
    if ($LASTEXITCODE -ne 0) { Stop-Publicacao "Falha: git $($GitArgs -join ' ')" }
}

$RaizPacote = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Stop-Publicacao "Git nao encontrado." }

# Confere os 17 arquivos cobertos pelo manifesto antes de iniciar a publicacao.
$Manifesto = Join-Path $RaizPacote "MANIFESTO_SHA256.txt"
if (-not (Test-Path -LiteralPath $Manifesto)) { Stop-Publicacao "Manifesto SHA-256 ausente." }
$Verificados = 0
foreach ($Linha in Get-Content -LiteralPath $Manifesto) {
    if ($Linha -match '^([0-9a-fA-F]{64})\s+\*?(.+)$') {
        $Relativo = $Matches[2].Replace('/', '\')
        if ($Relativo.StartsWith('.\')) { $Relativo = $Relativo.Substring(2) }
        $Arquivo = Join-Path $RaizPacote $Relativo
        if (-not (Test-Path -LiteralPath $Arquivo -PathType Leaf)) { Stop-Publicacao "Arquivo do manifesto ausente: $Relativo" }
        if ((Get-FileHash -LiteralPath $Arquivo -Algorithm SHA256).Hash -ine $Matches[1]) { Stop-Publicacao "Hash invalido: $Relativo" }
        $Verificados++
    }
}
if ($Verificados -ne 17) { Stop-Publicacao "Esperados 17 hashes; encontrados $Verificados." }
foreach ($Obrigatorio in @("index.html", "entrega.html", "README.md", "DOCUMENTO_ENTREGA.md", "PASSO_A_PASSO_WINDOWS.md", ".gitignore", ".nojekyll", "assets\uesb.png", "assets\uab.png", "css\style.css", "js\app.js", "js\exercicios.js", "docs\PW2_Exercicios_Cap_6_7_8_Thiago_Ferreira_Prates_Neves_CORRIGIDO.docx", "docs\PW2_Exercicios_Cap_6_7_8_Thiago_Ferreira_Prates_Neves_CORRIGIDO.pdf", "docs\enunciado_exercicios_6_7_8.pdf")) {
    if (-not (Test-Path -LiteralPath (Join-Path $RaizPacote $Obrigatorio))) { Stop-Publicacao "Arquivo obrigatorio ausente: $Obrigatorio" }
}

Write-Host "Pacote validado: $Verificados hashes. Repositorio: $Repositorio / $Branch" -ForegroundColor Green
$Confirmacao = Read-Host "A publicacao substituira o conteudo atual da branch. Digite LIMPAR para continuar"
if ($Confirmacao -cne "LIMPAR") { Stop-Publicacao "Operacao cancelada; nenhum push foi feito." }

$IdExecucao = [guid]::NewGuid().ToString("N")
$PastaTrabalho = Join-Path $env:TEMP "PW2_Publicacao_$IdExecucao"
$PastaClone = Join-Path $PastaTrabalho "PW2"
$Sentinela = Join-Path $PastaTrabalho ".pw2_temp_controlado"
New-Item -ItemType Directory -Path $PastaTrabalho | Out-Null
"PW2_TEMP_$IdExecucao" | Set-Content -LiteralPath $Sentinela -Encoding UTF8

Push-Location $PastaTrabalho
try { Invoke-Git clone $Repositorio "PW2" } finally { Pop-Location }
if (-not (Test-Path -LiteralPath (Join-Path $PastaClone ".git"))) { Stop-Publicacao "Clone sem .git." }
$BaseFull = [IO.Path]::GetFullPath($PastaTrabalho).TrimEnd('\') + '\'
$CloneFull = [IO.Path]::GetFullPath($PastaClone)
if (-not $CloneFull.StartsWith($BaseFull, [StringComparison]::OrdinalIgnoreCase)) { Stop-Publicacao "Clone fora da pasta exclusiva desta execucao." }
Set-Location $PastaClone
if (((& git remote get-url origin) | Out-String).Trim() -cne $Repositorio) { Stop-Publicacao "Remote origin inesperado." }

$BranchesIniciais = ((& git ls-remote --heads origin) | Out-String).Trim()
$LinhaMain = $BranchesIniciais -split "`n" | Where-Object { $_ -match "refs/heads/$([regex]::Escape($Branch))$" } | Select-Object -First 1
if ($BranchesIniciais -and -not $LinhaMain) { Stop-Publicacao "O remoto possui branches inesperadas; nenhuma alteracao foi feita." }
$CommitBase = ""
if ($LinhaMain) {
    Invoke-Git fetch origin $Branch
    $CommitBase = ((& git rev-parse "origin/$Branch") | Out-String).Trim()
    Invoke-Git checkout -B $Branch "origin/$Branch"
} else {
    Invoke-Git checkout -B $Branch
}
Write-Host "Base remota: $(if ($CommitBase) {$CommitBase} else {'repositorio vazio'})" -ForegroundColor Green

# Guardas antes da exclusao: caminho dentro do temp desta execucao, .git presente e origin exato.
if (-not $CloneFull.StartsWith($BaseFull, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath (Join-Path $PastaClone ".git")) -or (((& git remote get-url origin) | Out-String).Trim() -cne $Repositorio)) { Stop-Publicacao "Guardas do clone falharam; nada foi removido." }
Get-ChildItem -LiteralPath $PastaClone -Force | Where-Object { $_.Name -ne ".git" } | Remove-Item -Recurse -Force
Get-ChildItem -LiteralPath $RaizPacote -Force | Where-Object { $_.Name -ne ".git" } | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $PastaClone -Recurse -Force }
if (-not (Test-Path -LiteralPath (Join-Path $PastaClone "index.html")) -or -not (Test-Path -LiteralPath (Join-Path $PastaClone "entrega.html"))) { Stop-Publicacao "Paginas principais ausentes apos a copia." }

$NomeGit = ((& git config user.name) | Out-String).Trim()
$EmailGit = ((& git config user.email) | Out-String).Trim()
if (-not $NomeGit) { $NomeGit = Read-Host "Nome para o autor do commit"; Invoke-Git config user.name $NomeGit }
if (-not $EmailGit) { $EmailGit = Read-Host "E-mail para o autor do commit"; Invoke-Git config user.email $EmailGit }
Invoke-Git add -A
Invoke-Git status
if (((& git status --porcelain) | Out-String).Trim()) { Invoke-Git commit -m "Entrega PW2 - Exercicios capitulos 6, 7 e 8" }

$BranchesAgora = ((& git ls-remote --heads origin) | Out-String).Trim()
if ($BranchesAgora -cne $BranchesIniciais) { Stop-Publicacao "O remoto mudou durante a operacao; push cancelado." }
if ($CommitBase) {
    $MainAgora = ($BranchesAgora -split "`n" | Where-Object { $_ -match "refs/heads/$([regex]::Escape($Branch))$" } | Select-Object -First 1)
    if (-not $MainAgora -or (($MainAgora -split "\s+")[0] -ne $CommitBase)) { Stop-Publicacao "A branch remota mudou; push cancelado." }
}
Invoke-Git push -u origin $Branch
Invoke-Git fetch origin $Branch
if (((& git rev-parse HEAD) | Out-String).Trim() -ne ((& git rev-parse "origin/$Branch") | Out-String).Trim()) { Stop-Publicacao "HEAD e origin/$Branch nao conferem." }
Invoke-Git status
Invoke-Git log --oneline -5
Write-Host "Publicacao concluida. Commit: $((& git rev-parse HEAD) | Out-String). Repositorio: https://github.com/uesb-academicos/PW2" -ForegroundColor Green
Write-Host "Pasta temporaria preservada em $PastaTrabalho (sentinela: $Sentinela)." -ForegroundColor Yellow
