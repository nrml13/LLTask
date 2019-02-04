<#
.SYNOPSIS
  This file store the class with represent the state of a LLTask.
  LLState

.DESCRIPTION
  This class is using to represent the state of a LLTask.
  The usefull thing is the static variable Ref_State.
    
.PARAMETER Code
    An integer which represent the state.
.PARAMETER Key
    A short string which represent the state.
.PARAMETER Description
    A long string which describe the state.

.NOTES
  Version:        0.4
  Author:         Nrml13
  Creation Date:  04/02/2019
  Purpose : I Wanted to create an easy way of using runspaces to run concurrent tasks. Ended up with runspacePool
  
.EXAMPLE
  Go see Runner.ps1
#>
Class LLState
{
    [ValidateNotNullOrEmpty()][Int]$Code
    [ValidateNotNullOrEmpty()][String]$Key
    [ValidateNotNullOrEmpty()][String]$Description

    static [LLState[]]$Ref_State = @(`
        [LLState]::new(   -1, 'ERROR',            "Cet état correspond à une tâche en erreur."),
        [LLState]::new(    0, 'CREATED',          "Cet état correspond à une tâche crée mais qui n'a pas encore été initialisée."),
        [LLState]::new(    1, 'READY',            "Cet état correspond à une tâche dont le runspace est initialisé. La tache est prête a etre lancée"),
        [LLState]::new(    2, 'RUNNING',          "Cet état correspond à une tâche en cours d'exécution."),
        [LLState]::new(    3, 'COMPLETE',         "Cet état correspond à une tâche terminée.`nLa tâche présente des résultats."),
        [LLState]::new(    4, 'COMPLETE_RECEIVE', "Cet état correspond à une tâche terminée.`nLes résultats ont été récupérés.")
    )

    LLState(   [Int]$Code,    [String]$Key,    [String]$Description) {
        $this.Code = $Code
        $this.Key = $Key
        $this.Description = $Description
    }

    [String] ToString() {
        return $this.Key
    }
}