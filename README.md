# PSGraph Interactive Notebook

PSGraph is a set of utilities for working with Graphviz in Powershell. Written by [Kevin Marquette](https://github.com/KevinMarquette/PSGraph).

## Now it works in .NET Interactive Notebooks

![](/media/PSGraphOuput.png)

## Installation

You can install PSGraph from the PowerShell Gallery. `Install-Module -Name PSGraph`

Next, you need to have:

1. Visual Studio Code installed 
1. [.NET Interactive Notebooks extension](https://marketplace.visualstudio.com/items?itemName=ms-dotnettools.dotnet-interactive-vscode) installed
1. [The .NET 6 SDK](https://dotnet.microsoft.com/en-us/download/dotnet/6.0)

## Finally

Clone this repo. It has two things to get going. The interactive notebook `psgraph.ipynb` and the powershell script `psgraphNB.ps1` which enables you to output the PSGraph output inline in the notebook.

**Note**: You need to have the `PSGraph` module installed and check the docs to see how to install graphviz.