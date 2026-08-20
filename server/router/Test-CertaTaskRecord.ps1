#requires -Version 5.1

function Assert-CertaTaskRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Task,

        [string]$SourcePath = '<memory>'
    )

    $errors = New-Object System.Collections.Generic.List[string]
    $required = @('schema_version','task_id','created_at','request','inputs','preferred_lane','allowed_lanes','sensitivity','status','attempts','history')
    foreach ($name in $required) {
        if (-not $Task.PSObject.Properties[$name]) {
            $errors.Add("Missing required property '$name'.")
        }
    }

    if ($Task.PSObject.Properties['schema_version'] -and [int]$Task.schema_version -ne 1) {
        $errors.Add('schema_version must equal 1.')
    }
    if ($Task.PSObject.Properties['task_id'] -and [string]$Task.task_id -notmatch '^task-\d{8}-\d{6}-[a-f0-9]{8}$') {
        $errors.Add('task_id does not match the Certa task identifier format.')
    }
    if ($Task.PSObject.Properties['created_at']) {
        $created = [datetimeoffset]::MinValue
        if (-not [datetimeoffset]::TryParse([string]$Task.created_at, [ref]$created)) {
            $errors.Add('created_at is not a valid date-time.')
        }
    }
    if ($Task.PSObject.Properties['request'] -and [string]::IsNullOrWhiteSpace([string]$Task.request)) {
        $errors.Add('request must not be empty.')
    }

    $validLanes = @('SCRIPT','OLLAMA','CODEX','SPECIALIST','HUMAN')
    if ($Task.PSObject.Properties['allowed_lanes']) {
        $allowed = @($Task.allowed_lanes)
        if ($allowed.Count -eq 0) { $errors.Add('allowed_lanes must contain at least one lane.') }
        foreach ($lane in $allowed) {
            if ([string]$lane -notin $validLanes) { $errors.Add("Unknown allowed lane '$lane'.") }
        }
    }
    if ($Task.PSObject.Properties['preferred_lane'] -and $null -ne $Task.preferred_lane -and [string]$Task.preferred_lane -notin $validLanes) {
        $errors.Add("Unknown preferred lane '$($Task.preferred_lane)'.")
    }

    $validStatuses = @('NEW','ROUTED','CANDIDATE_COMPLETE','VALIDATED','FAILED','REVIEW_REQUIRED')
    if ($Task.PSObject.Properties['status'] -and [string]$Task.status -notin $validStatuses) {
        $errors.Add("Unknown task status '$($Task.status)'.")
    }
    $validSensitivities = @('NORMAL','COMPANY','CLIENT','RESTRICTED')
    if ($Task.PSObject.Properties['sensitivity'] -and [string]$Task.sensitivity -notin $validSensitivities) {
        $errors.Add("Unknown sensitivity '$($Task.sensitivity)'.")
    }
    if ($Task.PSObject.Properties['inputs']) {
        foreach ($inputPath in @($Task.inputs)) {
            if ([string]::IsNullOrWhiteSpace([string]$inputPath)) { $errors.Add('inputs must not contain empty paths.') }
        }
    }
    if ($Task.PSObject.Properties['attempts'] -and [int]$Task.attempts -lt 0) {
        $errors.Add('attempts must be zero or greater.')
    }

    if ($errors.Count -gt 0) {
        throw "Invalid Certa task record at $SourcePath`n- $($errors -join "`n- ")"
    }

    return $Task
}
