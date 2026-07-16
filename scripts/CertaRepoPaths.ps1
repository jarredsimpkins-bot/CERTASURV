function Resolve-CertaRepositoryPath {
    param(
        [Parameter(Mandatory)]
        [string]$Parent,

        [Parameter(Mandatory)]
        [string[]]$Names
    )

    foreach ($name in $Names) {
        $candidate = Join-Path $Parent $name
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return Join-Path $Parent $Names[0]
}

function Get-CertaRepositoryPaths {
    $controlRoot = Split-Path -Parent $PSScriptRoot
    $repositoryParent = if ($env:CERTA_REPOSITORY_PARENT) {
        [Environment]::ExpandEnvironmentVariables($env:CERTA_REPOSITORY_PARENT)
    }
    else {
        Split-Path -Parent $controlRoot
    }
    $documentsRoot = if ($env:CERTA_DOCUMENTS_ROOT) {
        [Environment]::ExpandEnvironmentVariables($env:CERTA_DOCUMENTS_ROOT)
    }
    elseif ((Split-Path -Leaf $repositoryParent) -eq 'Documents') {
        $repositoryParent
    }
    else {
        [Environment]::GetFolderPath('MyDocuments')
    }

    [pscustomobject]@{
        RepositoryParent = $repositoryParent
        DocumentsRoot = $documentsRoot
        Control = $controlRoot
        Certard = Resolve-CertaRepositoryPath -Parent $repositoryParent -Names @('certard', 'CERTARD')
        MacroTbc = Resolve-CertaRepositoryPath -Parent $repositoryParent -Names @('macrotbc', 'MACROTBC')
        Automations = Resolve-CertaRepositoryPath -Parent $repositoryParent -Names @('certasurv-automations', 'AUTOMATIONS')
        WebApp = Resolve-CertaRepositoryPath -Parent $repositoryParent -Names @(
            'certasurv-web-app',
            'CERTASURV_WEB_APP',
            'New project2'
        )
    }
}
