---
title: Commitment driven development
summary: There are multiple ways of planning your source control workflow. Let me introduce a quick tip that may speed your work when dealing with numerous issues during the day.  
date: 2023-01-02
tags: ["tips", git]
categories: [ideas]
draft: false
author: Michał Bryłka
---

There are multiple ways of planning your daily source control workflow. In most cases you need to contain commit message that contains some kind of bug tracker number (like [Jira](https://en.wikipedia.org/wiki/Jira_(software)), [YouTrack](https://en.wikipedia.org/wiki/YouTrack) etc.). Checks are usually installed as Git hooks and consequently commits may be revoked during push phase if they do not meet certain criteria.  
Let me introduce a quick tip that may speed your work (especially) when dealing with numerous issues during the day. This post describes how things can be achieved in Git SCM but similar workflows can be obtained in Mercurial as well. 


## TDD
Most of us are familiar with [test-driven development](https://en.wikipedia.org/wiki/Test-driven_development) approach. Even if we do not use it in our project (which usually means it's not test-oriented), TDD concept must be known by heart as it's a favorite topic among job recruiters :wink:. 

TDD as a methodology usually pivots around cycles that may look like that:
{{< figure src="TDD-circle-of-life.svg" caption="TDD lifecycle" >}}

It gives us more benefit if we are familiarized with it as follows: 
> Make it work. Make it right. Make it fast.

But usually this cycle is described for short as Red-Green-Refactor. I usually go one step forward and rephrase it as (Git/Mercurial only):
> red-commit(s)-green-commit(s)-refactor-commit(s)-[squash](https://www.git-tower.com/learn/git/faq/git-squash)-push

It's advisable to squash all (or most - depending on context) commits before pushing. Commits that we push outside should contain meaningful changes so that describing them should be easy. 

## Commitment driven development
Usual Git workflow dictates to perform some work, add our changes and commit them later on. We could however *commit* our work first and somewhat reverse this process. This way we are making a *commitment* to what we currently are dealing with. After all *commitment* is defined as
> an agreement or pledge to do something in the future
> 
> — <cite>Merriam-Webster[^1]</cite>

[^1]: [Commitment definition](https://www.merriam-webster.com/dictionary/commitment)


Git allows us to commit no changes by using
``` powershell
git commit --allow-empty -m "Some message"
``` 
Commits in source control should be coherent and contain commit message - at least these that are later on pushed to remote. I like to have small and coherent branches that get merged frequently - which has added benefit of close-to-zero merge conflicts. 

Thus I like to start with meaningful commit message that contains necessary bug track number and a description that will become final commit message after squash. Subsequent commit messages can be short or even gibberish as they (messages, not commits) will usually be discarded upon squashing of commits. Also sharing our history "milestones" like "added/fixed test XXX" is not adding value in most cases.

This script helps me in my workflow:

``` powershell
<#
    .SYNOPSIS
      Create WIP commit message   
    .EXAMPLE
     .\PutCddGitMessage.ps1 "Implement new important feature"
     Example output
     [feature/New-12345 b0d2215] New-12345 Implement new important feature
#>

[CmdletBinding()]
param (  
  [Parameter(Mandatory = $True)] [ValidateNotNullOrEmpty()] [Alias("m")] [string]$message
)

$branchName = git branch --show-current
if (($LASTEXITCODE -eq 0) -and ($branchName -match '.*?\/?(?<Issue>\w+-\d+)')) {
  $issue = $Matches. Issue
  $message = $message.Replace("\`"", "")
  $commitMessage = "${issue} ${message}"

  git commit --allow-empty -m "$commitMessage"
}
else {
  Write-Error "Not a git repo or invalid branch name (i.e. feature/PROJ-666)"
}
``` 

So right after creation of feature/bug branch I call:
``` powershell
PutCddGitMessage.ps1 "Implement optimized value string builder"
``` 
Let's assume that branch name was *feature/PROJ-666* then my generated commit message will be *"PROJ-666 Implement optimized value string builder"*

I can start adding some files/changes. They can be then committed:
``` powershell
git add .
git commit --amend
```
Commits can contain code that does not compile and tests that are failing (in *red* phase). Our branch is ours to use and only when we are synchronizing changes with others - they need to be coherent, contain meaningful messages, perfect (un-flaky) tests and refactored codebase - at least to extent of our current change. 

## Summary 
We introduced a simple script that may speed your daily workflow. Whether you install it as a module, script or a&nbsp;function in PowerShell profile, it's up to you.
As an added bonus Commitment Driven Development approach serves you as a reminder of what you're dealing with currently. You just type:
``` powershell
git log -n1
```
and your intentions for next few moments are clear. Forgetting what you are currently doing is not that uncommon especially in large teams. It doesn't happen to you but this particular mini tip may help your colleague greatly :wink:.  

After all, one can assume (both in real life as well as development) that:
> You won't achieve anything unless you commit (to) everything