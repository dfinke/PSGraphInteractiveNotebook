function New-Edge {
    param(
        $From,
        $To,
        $Attributes,
        [switch]$AsObject,
        [switch]$Undirected
    )

    $null = $PSBoundParameters.Remove('AsObject')
    $ht = [Hashtable]$PSBoundParameters
    if ($AsObject) {
        return [PSCustomObject]$ht
    }
    return $ht
}

function Get-Neighbours {
    param(
        $Edges,
        $Name,
        [switch]$Undirected
    )

    $edgeObjects = @($Edges)
    if (@($Edges)[0].GetType().FullName -ne 'System.Management.Automation.PSCustomObject') {
        $edgeObjects = foreach ($edge in $Edges) {
            [PSCustomObject]$edge
        }
    }
    (& {
            ($edgeObjects.where{ $_.From -eq $Name }).To
        if ($Undirected) {
                ($edgeObjects.where{ $_.To -eq $Name }).From
        }
    }).where{ ![String]::IsNullOrEmpty($_) }
}

function Get-LogSpace {
    param(
        [Double]$Minimum,
        [Double]$Maximum, 
        $Count
    )

    $increment = ($Maximum - $Minimum) / ($Count - 1)
    for ( $i = 0; $i -lt $Count; $i++ ) {
        [Math]::Pow( 10, ($Minimum + $increment * $i))
    }
}

function Get-RingLattice {
    param(
        $Nodes,
        $NumConnections
    )

    $ht = [ordered]@{}
    $ht.Nodes = $Nodes
    $cons = [int]($NumConnections / 2)
    $len = $Nodes.Count
    $ht.Edges = foreach ($node in $Nodes) {
        for ($i = $node + 1; $i -le ($node + $cons); $i++) {
            New-Edge $node $Nodes[($i % $len)] -AsObject
        }
    }
    $ht.Visual = graph {
        inline 'edge [arrowsize=0]'
        edge $ht.Edges -FromScript { $_.To } -ToScript { $_.From }
    }
    [PSCustomObject]$ht
}

function Get-SmallWorldGraph {
    param(
        $Nodes,
        $NumConnections,
        $Probability,
        [hashtable]$graphAttributes = @{}
    )
          
    $graph = Get-RingLattice $Nodes $NumConnections
    $edges = $graph.Edges.Clone()
    foreach ($edge in $graph.Edges) {
        $rand = (Get-Random -Minimum 0 -Maximum 10000) / 10000
        if ($rand -le $Probability) {
            $fromNeighbours = Get-Neighbours $graph.Edges $edge.From -Undirected
            #need to use foreach construct to expand nexted array of fromNeighbours
            $exclude = $edge.From, $edge.To, ($fromNeighbours.foreach{ $_ })
            $toConnect = $graph.Nodes.where{ $_ -notin ($exclude.foreach{ $_ }) }
            #remove the current edge
            #see https://en.wikipedia.org/wiki/De_Morgan%27s_laws
            $graph.Edges = $graph.Edges.where{ $_.From -ne $edge.From -or $_.To -ne $edge.To }
            #add the new edge += for "adding to an array is bad but good enough in this case
            $graph.Edges += New-Edge $edge.From (Get-Random -InputObject $toConnect) -AsObject
        }
    }
    #redo the visual part based on the new edges
    $graph.Visual = graph $graphAttributes {
        inline 'edge [arrowsize=0]'
        edge $graph.Edges -FromScript { $_.To } -ToScript { $_.From }
    }
    $graph
}

function Get-ClusteringCoefficient {
    param(
        $Graph
    )

    $individualCEs = foreach ($node in $Graph.Nodes) {
        $neighbours = Get-Neighbours $Graph.Edges $node -Undirected
        $numNeighbours = $neighbours.Count
        #CE undefined skip to next node
        if ($numNeighbours -lt 2) { 
            [Single]::NaN 
            continue
        }
        $possibleConnections = $numNeighbours * ($numNeighbours - 1) / 2
        $nodes = $Graph.Nodes
        $actualConnections = for ($i = 0; $i -lt $numNeighBours; $i++) {
            for ($j = 0; $j -lt $neighbours.Count; $j++) {
                if ($i -lt $j) {
                    $l = $neighbours[$i]
                    $r = $neighbours[$j]
                    #the way the edge objects are setup currently we will need to check for both sides
                    #would be better to setup sundirected edges differently
                    $Graph.Edges.where{ ($_.From -eq $l -and $_.To -eq $r) -or ($_.From -eq $r -and $_.To -eq $l) }   
                }
            }
        }
        ($actualConnections.Count / $possibleConnections)
    }
    #return the average of the clustering coefficients per node exlcuding NaNs
    ($individualCEs.where{ -not ([Single]::IsNaN($_)) } | Measure-Object -Average).Average
}

function Get-ShortestPath {
    param(
        $Graph,
        $StartNode
    )
    
    #distances keeps track of distances from the start node for each node
    $distances = @{$StartNode = 0 }
    #usage of linked list to be able to add at the end (like in a stack) and remove from the beginning (like in a queue)
    $list = New-Object System.Collections.Generic.LinkedList[int]
    $null = $list.AddFirst($StartNode)
    while ($list.Count -gt 0) {
        #get the first element from the linked list
        $node = $list.First.Value
        $null = $list.RemoveFirst()
        $neighbours = Get-Neighbours $Graph.Edges $node -Undirected 
        #find the neighbours that are not already contained in the hashtable
        $neighbours = $neighbours.where{ $_ -notin $distances.Keys }
        foreach ($neighbour in $neighbours) {
            #the distance to the neighbour is, by defintion, the current node's distance + 1
            $distances.$neighbour = $distances.$node + 1
            #add the neighbour to the list to discover further connections
            $null = $list.AddLast($neighbour)
        }
    }
    $distances.GetEnumerator().foreach{
        [PSCustomObject][ordered]@{
            Source      = $startNode
            Destination = $_.Name
            Distance    = $_.Value
        }
    }
}
