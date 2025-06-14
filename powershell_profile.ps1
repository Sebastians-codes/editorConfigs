# PowerShell Profile - Git & GitHub Functions

# Basic Git aliases
function gs { git status }
function ga { git add $args }
function gaa { git add . }
function gc { git commit -m $args }
function gps { git push }
function gpl { git pull }
function gst { git stash }
function gstp { git stash pop }
function gstl { git stash list }
function gstd { git stash drop }

# Create new branch and push to origin
function gnewb {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BranchName
    )
    
    Write-Host "Creating and switching to branch: ${BranchName}" -ForegroundColor Green
    git checkout -b $BranchName
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Pushing branch to origin..." -ForegroundColor Yellow
        git push -u origin $BranchName
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Branch '${BranchName}' created and pushed!" -ForegroundColor Green
        }
        else {
            Write-Host "Failed to push branch" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Failed to create branch" -ForegroundColor Red
    }
}

# Switch to existing branch
function gco {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BranchName
    )
    
    Write-Host "Switching to branch: ${BranchName}" -ForegroundColor Green
    git checkout $BranchName
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Switched to branch '${BranchName}'" -ForegroundColor Green
    }
    else {
        Write-Host "Failed to switch to branch '${BranchName}'" -ForegroundColor Red
        Write-Host "Branch might not exist. Use 'gnewb ${BranchName}' to create it." -ForegroundColor Yellow
    }
}

# List all branches
function gb {
    Write-Host "All branches:" -ForegroundColor Cyan
    git branch -a
}

# List local branches only
function gbl {
    Write-Host "Local branches:" -ForegroundColor Cyan
    git branch
}

# Delete branch (local and remote)
function gdel {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BranchName
    )
    
    Write-Host "Deleting branch: ${BranchName}" -ForegroundColor Yellow
    
    # Switch to main if we're on the branch we want to delete
    $currentBranch = $(git branch --show-current)
    if ($currentBranch -eq $BranchName) {
        Write-Host "Switching to main first..." -ForegroundColor Yellow
        git checkout main
    }
    
    # Delete local branch
    git branch -d $BranchName
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Local branch '${BranchName}' deleted" -ForegroundColor Green
        
        # Try to delete remote branch
        git push origin --delete $BranchName 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Remote branch '${BranchName}' deleted" -ForegroundColor Green
        }
        else {
            Write-Host "Remote branch '${BranchName}' might not exist or already deleted" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Failed to delete local branch. Use 'git branch -D ${BranchName}' to force delete." -ForegroundColor Red
    }
}

# Create new GitHub repository
function gnewrepo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoName,
        [string]$Description = "Created via command line"
    )
    
    Write-Host "Creating private repository: ${RepoName}" -ForegroundColor Green
    
    $result = gh repo create $RepoName --private --description $Description
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Repository created on GitHub" -ForegroundColor Green
        
        if (!(Test-Path ".git")) {
            git init
            Write-Host "Initialized local git repository" -ForegroundColor Yellow
        }
        
        # Remove origin if it already exists
        $remoteExists = git remote get-url origin 2>$null
        if ($remoteExists) {
            Write-Host "Removing existing origin remote" -ForegroundColor Yellow
            git remote remove origin
        }
        
        $username = $(gh api user --jq .login)
        git remote add origin "https://github.com/${username}/${RepoName}.git"
        Write-Host "Remote origin added" -ForegroundColor Green
        
        # Check if there are files to commit
        $files = Get-ChildItem -Force | Where-Object { $_.Name -ne ".git" }
        if ($files) {
            Write-Host "Files found in directory" -ForegroundColor Yellow
            $response = Read-Host "Create initial commit with current files? (y/n)"
            if ($response -eq "y" -or $response -eq "Y") {
                git add .
                git commit -m "Initial commit"
                git branch -M main
                git push -u origin main
                Write-Host "Initial commit pushed!" -ForegroundColor Green
            }
        }
        else {
            Write-Host "No files in current directory" -ForegroundColor Yellow
        }
        
        Write-Host "Repository URL: https://github.com/${username}/${RepoName}" -ForegroundColor Cyan
    }
    else {
        Write-Host "Failed to create repository" -ForegroundColor Red
        return 1
    }
}

# Create Pull Request
function gpr {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        [string]$Body = "",
        [string]$Base = "main"
    )
    
    $currentBranch = $(git branch --show-current)
    Write-Host "Creating PR: ${Title}" -ForegroundColor Green
    Write-Host "From: ${currentBranch} to ${Base}" -ForegroundColor Yellow
    
    $result = gh pr create --title $Title --body $Body --base $Base
    if ($LASTEXITCODE -eq 0) {
        Write-Host "PR created successfully!" -ForegroundColor Green
        gh pr view --web
    }
    else {
        Write-Host "Failed to create PR" -ForegroundColor Red
        return 1
    }
}

# List Pull Requests
function prs {
    Write-Host "Open Pull Requests:" -ForegroundColor Cyan
    gh pr list
}

# View specific PR
function prv {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PrNumber
    )
    
    Write-Host "Viewing PR #${PrNumber}:" -ForegroundColor Cyan
    gh pr view $PrNumber
}

# Approve PR
function prapprove {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PrNumber,
        [string]$Comment = "LGTM!"
    )
    
    Write-Host "Approving PR #${PrNumber}..." -ForegroundColor Green
    gh pr review $PrNumber --approve --body $Comment
    Write-Host "PR #${PrNumber} approved!" -ForegroundColor Green
}

# Request changes on PR
function prchanges {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PrNumber,
        [Parameter(Mandatory = $true)]
        [string]$Comment
    )
    
    Write-Host "Requesting changes on PR #${PrNumber}..." -ForegroundColor Yellow
    gh pr review $PrNumber --request-changes --body $Comment
    Write-Host "Changes requested on PR #${PrNumber}" -ForegroundColor Yellow
}

# Merge PR
function gmerge {
    param(
        [string]$MergeType = "merge"
    )
    
    switch ($MergeType.ToLower()) {
        "squash" { 
            Write-Host "Squash merging PR..." -ForegroundColor Yellow
            gh pr merge --squash --delete-branch 
        }
        "rebase" { 
            Write-Host "Rebase merging PR..." -ForegroundColor Yellow
            gh pr merge --rebase --delete-branch 
        }
        default { 
            Write-Host "Merge committing PR..." -ForegroundColor Yellow
            gh pr merge --merge --delete-branch 
        }
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "PR merged and branch deleted!" -ForegroundColor Green
        git checkout main
        git pull origin main
        Write-Host "Switched to main and pulled latest changes" -ForegroundColor Green
    }
}

# Quick aliases for PR operations
function prl { gh pr list }
function prc { gh pr checks $args }
function prd { gh pr diff $args }
function prco { gh pr checkout $args }

# Help function - lists all custom Git/GitHub functions
function ghelp {
    Write-Host "`n=== Git & GitHub Helper Functions ===" -ForegroundColor Cyan
    Write-Host "`nBASIC GIT COMMANDS:" -ForegroundColor Yellow
    Write-Host "  gs              - git status" -ForegroundColor White
    Write-Host "  ga <files>      - git add <files>" -ForegroundColor White  
    Write-Host "  gaa             - git add . (add all files)" -ForegroundColor White
    Write-Host "  gc <message>    - git commit -m <message>" -ForegroundColor White
    Write-Host "  gps             - git push" -ForegroundColor White
    Write-Host "  gpl             - git pull" -ForegroundColor White
    Write-Host "  gst             - git stash" -ForegroundColor White
    Write-Host "  gstp            - git stash pop" -ForegroundColor White
    Write-Host "  gstl            - git stash list" -ForegroundColor White
    Write-Host "  gstd            - git stash drop" -ForegroundColor White
    
    Write-Host "`nBRANCH MANAGEMENT:" -ForegroundColor Yellow
    Write-Host "  gnewb <name>    - Create new branch and push to origin" -ForegroundColor White
    Write-Host "                    Example: gnewb feature-login" -ForegroundColor Gray
    
    Write-Host "`nREPOSITORY MANAGEMENT:" -ForegroundColor Yellow
    Write-Host "  gnewrepo <name> [description]" -ForegroundColor White
    Write-Host "                  - Create new private GitHub repo and set remote" -ForegroundColor White
    Write-Host "                    Example: gnewrepo my-project 'Cool new app'" -ForegroundColor Gray
    
    Write-Host "`nPULL REQUEST CREATION:" -ForegroundColor Yellow
    Write-Host "  gpr <title> [body] [base]" -ForegroundColor White
    Write-Host "                  - Create pull request" -ForegroundColor White
    Write-Host "                    Example: gpr 'Add login' 'New feature' main" -ForegroundColor Gray
    
    Write-Host "`nPULL REQUEST VIEWING:" -ForegroundColor Yellow
    Write-Host "  prs             - List all open pull requests" -ForegroundColor White
    Write-Host "  prv <number>    - View specific PR details" -ForegroundColor White
    Write-Host "                    Example: prv 123" -ForegroundColor Gray
    Write-Host "  prl             - List PRs (alias for prs)" -ForegroundColor White
    Write-Host "  prc <number>    - Check PR status/checks" -ForegroundColor White
    Write-Host "  prd <number>    - View PR diff" -ForegroundColor White
    Write-Host "  prco <number>   - Checkout PR branch locally" -ForegroundColor White
    
    Write-Host "`nPULL REQUEST REVIEW:" -ForegroundColor Yellow
    Write-Host "  prapprove <number> [comment]" -ForegroundColor White
    Write-Host "                  - Approve a pull request" -ForegroundColor White
    Write-Host "                    Example: prapprove 123 'Great work!'" -ForegroundColor Gray
    Write-Host "  prchanges <number> <comment>" -ForegroundColor White
    Write-Host "                  - Request changes on PR (comment required)" -ForegroundColor White
    Write-Host "                    Example: prchanges 123 'Please add tests'" -ForegroundColor Gray
    
    Write-Host "`nPULL REQUEST MERGING:" -ForegroundColor Yellow
    Write-Host "  gmerge [type]   - Merge current branch's PR" -ForegroundColor White
    Write-Host "                    Types: merge (default), squash, rebase" -ForegroundColor White
    Write-Host "                    Example: gmerge squash" -ForegroundColor Gray
    
    Write-Host "`nHELP:" -ForegroundColor Yellow
    Write-Host "  ghelp           - Show this help message" -ForegroundColor White
    
    Write-Host "`n=== Usage Examples ===" -ForegroundColor Cyan
    Write-Host "# Complete workflow:" -ForegroundColor Green
    Write-Host "gb                          # List branches" -ForegroundColor White
    Write-Host "gnewb feature-auth          # Create new branch" -ForegroundColor White
    Write-Host "# ... make changes ..." -ForegroundColor Gray
    Write-Host "ga ." -ForegroundColor White
    Write-Host "gc 'Add authentication'" -ForegroundColor White  
    Write-Host "gps                         # Push changes" -ForegroundColor White
    Write-Host "gpr 'Add user auth' 'New login system'" -ForegroundColor White
    Write-Host "# ... wait for review ..." -ForegroundColor Gray
    Write-Host "gmerge                      # Merge when approved" -ForegroundColor White
    Write-Host "gco main                    # Switch back to main" -ForegroundColor White
    Write-Host "gdel feature-auth           # Delete merged branch" -ForegroundColor White
    Write-Host ""
}

Write-Host "Git & GitHub functions loaded successfully!" -ForegroundColor Green
Write-Host "Type 'ghelp' to see all available commands and examples" -ForegroundColor Cyan
